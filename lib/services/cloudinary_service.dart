import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryService {
  final String cloudName = 'ddeqgfo0c';
  final String uploadPreset = 'inspetto';

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
