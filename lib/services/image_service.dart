import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageService {
  // Get your FREE API key from https://api.imgbb.com/
  static const String _apiKey = '26bd732163c314446091c2a957099ef7';
  
  // Upload image to ImgBB (100% FREE)
  Future<String?> uploadImage(File imageFile, {String folder = 'campus_events'}) async {
    try {
      // Read image bytes
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Upload to ImgBB
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {
          'key': _apiKey,
          'image': base64Image,
          'name': '${folder}_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['data']['url'];
      } else {
        print('Upload failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Upload profile image
  Future<String?> uploadProfileImage(File imageFile) async {
    return await uploadImage(imageFile, folder: 'profile');
  }

  // Upload event image
  Future<String?> uploadEventImage(File imageFile) async {
    return await uploadImage(imageFile, folder: 'event');
  }
}