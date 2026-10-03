import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class StorageService {
  static Future<String> uploadReceipt(String path) async {
    final file = File(path);

    final ref = FirebaseStorage.instance
        .ref()
        .child("receipts/${DateTime.now().millisecondsSinceEpoch}.jpg");

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}