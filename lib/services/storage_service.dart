import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // Pick image from gallery
  Future<File?> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;

      return File(image.path);
    } catch (e) {
      throw Exception('Erro ao selecionar imagem: $e');
    }
  }

  // Upload user logo
  Future<String> uploadLogo(String userId, File file) async {
    try {
      final String fileName = '${_uuid.v4()}.${file.path.split('.').last}';
      final String filePath = '${AppConstants.logosPath}/$userId/$fileName';

      final Reference ref = _storage.ref().child(filePath);

      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/${file.path.split('.').last}',
          customMetadata: {
            'uploaded_by': userId,
            'uploaded_at': DateTime.now().toIso8601String(),
          },
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Erro ao fazer upload da logo: $e');
    }
  }

  // Delete logo
  Future<void> deleteLogo(String logoUrl) async {
    try {
      final Reference ref = _storage.refFromURL(logoUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Erro ao excluir logo: $e');
    }
  }

  // Get download URL
  Future<String> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erro ao obter URL de download: $e');
    }
  }
}
