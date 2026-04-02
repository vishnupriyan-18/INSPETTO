import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadVisitPhoto(
      String taskId, String officerId, File imageFile) async {
    final fileName =
        '${officerId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref =
        _storage.ref().child('visits/$taskId/$fileName');
    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadSignature(
      String taskId, String officerId, Uint8List signatureBytes) async {
    final fileName =
        'sig_${officerId}_${DateTime.now().millisecondsSinceEpoch}.png';
    final ref =
        _storage.ref().child('signatures/$taskId/$fileName');
    final uploadTask = await ref.putData(
      signatureBytes,
      SettableMetadata(contentType: 'image/png'),
    );
    return await uploadTask.ref.getDownloadURL();
  }
}
