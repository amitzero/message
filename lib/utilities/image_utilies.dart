import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ImageUtilities {
  static Future<File?> pickImage(BuildContext context) async {
    final source = await showDialog(
      context: context,
      builder: (_) => SizedBox(
        height: 100,
        width: MediaQuery.of(context).size.width - 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context, ImageSource.camera);
              },
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.camera_alt),
                      Text('Capture Image'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20, height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pop(context, ImageSource.gallery);
              },
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.photo_library),
                      Text('Choose Image'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (source == ImageSource.camera) {
      var imageFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
      );
      if (imageFile != null) {
        return File(imageFile.path);
      }
    } else if (source == ImageSource.gallery) {
      try {
        var filePickerResult = await FilePicker.platform.pickFiles(
          dialogTitle: 'Select Profile Image',
          type: FileType.image,
          onFileLoading: (status) {
            log('$status', name: 'file loading');
          },
        );
        log('$filePickerResult', name: 'filePickerResult');
        if (filePickerResult != null) {
          return File(filePickerResult.files.single.path!);
        }
      } on PlatformException catch (e) {
        log('Unsupported operation' + e.toString());
      } catch (e) {
        log(e.toString());
      }
    }
    return null;
  }

  static Future<Map<String, String>?> uploadImage({
    required File imageFile,
    required String fileName,
    void Function(TaskSnapshot)? onSnapshot,
  }) async {
    final uploadTask =
        FirebaseStorage.instance.ref().child('images/$fileName').putFile(
              imageFile,
              SettableMetadata(
                customMetadata: {
                  'upload': DateTime.now().millisecondsSinceEpoch.toString(),
                },
              ),
            );
    await for (final snapshot in uploadTask.snapshotEvents) {
      onSnapshot?.call(snapshot);
      if (snapshot.state == TaskState.success) {
        return {
          'path': snapshot.ref.fullPath,
          'url': await snapshot.ref.getDownloadURL(),
        };
      } else if (snapshot.state == TaskState.error) {
        log(snapshot.state.toString(), name: 'snapshot error');
        return null;
      }
    }
    return null;
  }
}
