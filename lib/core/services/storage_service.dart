import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

class StorageService {
  Future<String> uploadFile({
    required File file,
    required String folder,
    void Function(double progress)? onProgress,
  }) async {
    // TEMPORARY: Return a placeholder instead of using Firebase Storage
    // This avoids the 404 error while Storage is not enabled in the console.
    await Future.delayed(const Duration(milliseconds: 500));
    if (onProgress != null) onProgress(1.0);
    return 'https://ui-avatars.com/api/?name=User&background=random';
  }

  Future<void> deleteFile(String url) async {
    // TEMPORARY: Do nothing
  }
}
