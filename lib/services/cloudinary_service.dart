import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class CloudinaryService {
  final String cloudName = 'ddeqgfo0c';
  final String uploadPreset = 'inspetto';
  final String apiKey = '882894567484439'; // Placeholder - user to update
  final String apiSecret = 'iitV0s1o4B8xT8YmB_8mN_8mN_8'; // Placeholder - user to update

  /// Extracts the Public ID from a Cloudinary URL.
  String? _extractPublicId(String url) {
    if (url.isEmpty) return null;
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.length < 4) return null;

      // Find index of 'upload'
      int uploadIdx = segments.indexOf('upload');
      if (uploadIdx == -1 || uploadIdx + 2 >= segments.length) return null;

      // Public ID is everything between version (vXXXX) and extension
      final afterUpload = segments.sublist(uploadIdx + 2);
      String publicIdWithExt = afterUpload.join('/');

      // Remove extension
      int lastDot = publicIdWithExt.lastIndexOf('.');
      return lastDot == -1 ? publicIdWithExt : publicIdWithExt.substring(0, lastDot);
    } catch (e) {
      return null;
    }
  }

  /// Deletes an image from Cloudinary using its URL.
  Future<void> deleteImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    final publicId = _extractPublicId(imageUrl);
    if (publicId == null) return;

    print('Deleting asset from Cloudinary: $publicId');
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Generate Signature: sha1(public_id=<public_id>&timestamp=<timestamp><api_secret>)
    final signatureString = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
    final signature = sha1.convert(utf8.encode(signatureString)).toString();

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy');
    try {
      final response = await http.post(url, body: {
        'public_id': publicId,
        'timestamp': timestamp.toString(),
        'api_key': apiKey,
        'signature': signature,
      });

      if (response.statusCode == 200) {
        print('Cloudinary deletion success: $publicId');
      } else {
        print('Cloudinary deletion failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error calling Cloudinary destroy: $e');
    }
  }

  /// Deletes multiple images in parallel.
  Future<void> deleteMultipleImages(List<String> urls) async {
    if (urls.isEmpty) return;
    await Future.wait(urls.map((url) => deleteImage(url)));
  }

  /// Uploads a [File] to Cloudinary and returns the [secure_url].
  Future<String?> uploadImageToCloudinary(File imageFile) async {
    print('Uploading image to Cloudinary...');
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseData);
        final secureUrl = jsonResponse['secure_url'] as String;
        print('Upload success');
        print('secure_url: $secureUrl');
        return secureUrl;
      } else {
        final errorResponse = await response.stream.bytesToString();
        print('Upload failed with status: ${response.statusCode}');
        print('Error response: $errorResponse');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  /// Uploads [Uint8List] bytes to Cloudinary and returns the [secure_url].
  Future<String?> uploadBytesToCloudinary(Uint8List bytes, String fileName) async {
    print('Uploading bytes to Cloudinary...');
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseData);
        final secureUrl = jsonResponse['secure_url'] as String;
        print('Upload success');
        print('secure_url: $secureUrl');
        return secureUrl;
      } else {
        final errorResponse = await response.stream.bytesToString();
        print('Upload failed with status: ${response.statusCode}');
        print('Error response: $errorResponse');
        return null;
      }
    } catch (e) {
      print('Error uploading bytes to Cloudinary: $e');
      return null;
    }
  }
}
