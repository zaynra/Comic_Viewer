import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../application/usecases/library_folder_usecases.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/data_providers.dart';
import '../../../data/repositories/library_folder_repository_impl.dart';
import '../../../domain/entities/library_folder.dart';
import '../../../domain/repositories/library_folder_repository.dart';
import '../../../infrastructure/services/file_watcher_service.dart';
import '../../../infrastructure/services/folder_picker_service.dart';
import '../../settings/providers/settings_provider.dart';

final libraryFolderRepositoryProvider =
    FutureProvider<LibraryFolderRepository>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LibraryFolderRepositoryImpl(prefs);
});

final pickLibraryFolderProvider =
    FutureProvider<PickLibraryFolder>((ref) async {
  final repository = await ref.watch(libraryFolderRepositoryProvider.future);
  return PickLibraryFolder(FolderPickerService(), repository);
});

final getSavedLibraryFolderProvider =
    FutureProvider<GetSavedLibraryFolder>((ref) async {
  final repository = await ref.watch(libraryFolderRepositoryProvider.future);
  return GetSavedLibraryFolder(repository);
});

class LibraryFolderNotifier extends AsyncNotifier<LibraryFolder?> {
  @override
  Future<LibraryFolder?> build() async {
    final getSaved = await ref.watch(getSavedLibraryFolderProvider.future);
    final folder = await getSaved();

    if (folder != null) {
      final canRead = await _canReadDirectory(folder.path);
      if (canRead) {
        debugPrint('[FOLDER] Auto-scanning saved folder: ${folder.path}');
        ref.read(scanNotifierProvider.notifier).scanFolder(folder.path);
        _startWatching(folder.path);
      } else {
        debugPrint('[FOLDER] Cannot read saved folder: ${folder.path}');
      }
    }

    return folder;
  }

  Future<bool> _canReadDirectory(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) return false;
      dir.listSync();
      return true;
    } catch (e) {
      debugPrint('[FOLDER] Cannot read directory: $e');
      return false;
    }
  }

  Future<bool> ensureStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    final status = await Permission.manageExternalStorage.status;
    debugPrint('[FOLDER] Permission status: $status');

    if (status.isPermanentlyDenied || status.isDenied) {
      if (context.mounted) {
        final granted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Symbols.folder_off, size: 48, color: AppColors.error),
            title: const Text('Izin Diperlukan'),
            content: const Text(
              'Aplikasi membutuhkan izin "Akses semua file" untuk membaca komik dari folder penyimpanan.\n\n'
              'Tap "Buka Pengaturan" lalu aktifkan izin untuk Comic Viewer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Buka Pengaturan'),
              ),
            ],
          ),
        );

        if (granted == true) {
          await openAppSettings();
          return false;
        }
      }
      return false;
    }

    final result = await Permission.manageExternalStorage.request();
    return result.isGranted;
  }

  Future<void> pickFolder(BuildContext context) async {
    final previous = state.valueOrNull;
    state = const AsyncLoading();
    try {
      final hasPermission = await ensureStoragePermission(context);
      if (!hasPermission) {
        debugPrint('[FOLDER] Permission not granted');
        state = AsyncData(previous);
        return;
      }

      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Pilih folder komik',
      );

      if (result == null) {
        debugPrint('[FOLDER] User cancelled picker');
        state = AsyncData(previous);
        return;
      }

      debugPrint('[FOLDER] Picked folder: $result');

      final canRead = await _canReadDirectory(result);
      if (!canRead) {
        debugPrint('[FOLDER] Cannot read picked folder!');
        state = AsyncData(previous);
        return;
      }

      final repository = await ref.read(libraryFolderRepositoryProvider.future);
      final folder = LibraryFolder(
        path: result,
        pickedAt: DateTime.now(),
      );
      await repository.saveFolder(result);
      state = AsyncData(folder);

      ref.read(scanNotifierProvider.notifier).scanFolder(result);
      _startWatching(result);
    } catch (error, stackTrace) {
      debugPrint('[FOLDER] Error picking folder: $error');
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> setFolderPath(BuildContext context, String path) async {
    state = const AsyncLoading();
    try {
      debugPrint('[FOLDER] setFolderPath: $path');

      final hasPermission = await ensureStoragePermission(context);
      if (!hasPermission) {
        state = AsyncData(state.valueOrNull);
        return;
      }

      final canRead = await _canReadDirectory(path);
      if (!canRead) {
        debugPrint('[FOLDER] Cannot read path: $path');
        state = AsyncData(state.valueOrNull);
        return;
      }

      final repository = await ref.read(libraryFolderRepositoryProvider.future);
      final folder = LibraryFolder(
        path: path,
        pickedAt: DateTime.now(),
      );
      await repository.saveFolder(path);
      debugPrint('[FOLDER] Folder saved: $path');
      state = AsyncData(folder);

      ref.read(scanNotifierProvider.notifier).scanFolder(path);
      _startWatching(path);
    } catch (error, stackTrace) {
      debugPrint('[FOLDER] Error: $error');
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> clearFolder() async {
    state = const AsyncLoading();
    try {
      final repository = await ref.read(libraryFolderRepositoryProvider.future);
      await repository.clearFolder();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  void _startWatching(String folderPath) {
    final watcher = ref.read(fileWatcherServiceProvider);
    watcher.startWatching(folderPath);

    ref.listen<AsyncValue<WatchResult?>>(fileWatcherResultProvider, (prev, next) {
      if (next.valueOrNull != null && next.valueOrNull!.hasChanges) {
        ref.invalidate(allSeriesProvider);
      }
    });
  }
}

final fileWatcherResultProvider = StreamProvider<WatchResult>((ref) async* {
  final watcher = ref.watch(fileWatcherServiceProvider);
  final stream = watcher.onChanges;
  if (stream != null) {
    yield* stream;
  }
});

final libraryFolderNotifierProvider =
    AsyncNotifierProvider<LibraryFolderNotifier, LibraryFolder?>(
  LibraryFolderNotifier.new,
);
