import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../onboding/api_constants.dart';

class PickImage extends StatefulWidget {
  const PickImage({super.key});

  @override
  _PickImageState createState() => _PickImageState();
}

class _PickImageState extends State<PickImage> {
  Uint8List? _image;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _getImageFromUserId();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: [
            _image != null
                ? CircleAvatar(
              radius: 100,
              backgroundImage: MemoryImage(_image!),
            )
                : _imageUrl != null
                ? CircleAvatar(
              radius: 100,
              backgroundImage: NetworkImage(_imageUrl!),
            )
                : const CircleAvatar(
              radius: 100,
              backgroundImage: NetworkImage(
                  "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png"),
            ),
            Positioned(
              bottom: 0,
              left: 140,
              child: IconButton(
                onPressed: () {
                  showImagePickerOption(context);
                },
                icon: const Icon(Icons.add_a_photo),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showImagePickerOption(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.blue[100],
      context: context,
      builder: (builder) {
        return Padding(
          padding: const EdgeInsets.all(18.0),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 4.5,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _pickImageFromGallery();
                    },
                    child: const SizedBox(
                      child: Column(
                        children: [
                          Icon(
                            Icons.image,
                            size: 70,
                          ),
                          Text("Gallery")
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _pickImageFromCamera();
                    },
                    child: const SizedBox(
                      child: Column(
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 70,
                          ),
                          Text("Camera")
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    final returnImage =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnImage == null) return;
    final imagePath = returnImage.path;
    final imageBytes = await File(imagePath).readAsBytes();

    setState(() {
      _image = imageBytes;
    });

    await _uploadImageToMongoDB(imageBytes);
  }

  Future<void> _pickImageFromCamera() async {
    final returnImage =
    await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnImage == null) return;
    final imagePath = returnImage.path;
    final imageBytes = await File(imagePath).readAsBytes();

    setState(() {
      _image = imageBytes;
    });

    await _uploadImageToMongoDB(imageBytes);
  }

  Future<void> _uploadImageToMongoDB(Uint8List imageBytes) async {
    const storage = FlutterSecureStorage();
    final String? token = await storage.read(key: 'token');

    if (token == null) {
      print('Token non disponible');
      return;
    }

    final base64Image = base64Encode(imageBytes);

    final String? userId = await storage.read(key: 'userId');

    if (userId == null) {
      print('Identifiant utilisateur non disponible');
      return;
    }

    final imageData = {
      'image': base64Image,
      'userId': userId,
    };

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.imageUploadUrl),
        body: imageData,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final imageUrl = jsonDecode(response.body)['imageUrl'];

        setState(() {
          _imageUrl = imageUrl;
        });
      } else {
        print('Erreur lors de l\'enregistrement de l\'image sur le serveur');
      }
    } catch (e) {
      print('Erreur lors de l\'envoi des données de l\'image : $e');
    }
  }

  Future<void> _getImageFromUserId() async {
    const storage = FlutterSecureStorage();
    final userId = await storage.read(key: 'userId');

    if (userId != null) {
      final imageBytes = await _fetchUserImageFromApi(userId);
      if (imageBytes != null) {
        setState(() {
          _image = imageBytes;
        });
      }
    }
  }

  Future<Uint8List?> _fetchUserImageFromApi(String userId) async {
    const storage = FlutterSecureStorage();
    final String? token = await storage.read(key: 'token');

    if (token == null) {
      print('Token non disponible');
      return null;
    }

    final apiUrl = Uri.parse('${ApiConstants.baseUrl}/user/$userId/image');

    try {
      final response = await http.get(
        apiUrl,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else if (response.statusCode == 404) {
        print('Aucune image trouvée pour cet utilisateur');
        return null;
      } else {
        print('Erreur lors de la récupération de l\'image : ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'image : $e');
      return null;
    }
  }
}
