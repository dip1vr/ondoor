import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ImgBBService {
  static const String apiKey = '87ac08b1fe96f1eec8ec5a764548dd56';
  static const String apiUrl = 'https://api.imgbb.com/1/upload';

  /// Uploads an image file to ImgBB and returns the public URL.
  /// Throws an exception if the upload fails.
  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      // 1. Convert image to Base64
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // 2. Prepare the request
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'key': apiKey, 'image': base64Image},
      );

      // 3. Parse the response
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data']['url'];
        } else {
          throw Exception(
            'ImgBB API Error: ${jsonResponse['error']['message']}',
          );
        }
      } else {
        throw Exception(
          'Failed to upload image. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('ImgBB Upload Error: $e');
      rethrow;
    }
  }
}
