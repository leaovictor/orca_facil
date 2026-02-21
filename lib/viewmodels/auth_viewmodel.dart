import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Firestore Service Provider
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

// Current Firebase User Stream
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current User Model Stream
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return firestoreService.getUserStream(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, _) => Stream.value(null),
  );
});

// Auth ViewModel for handling login/register
class AuthViewModel extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthViewModel(this._authService, this._firestoreService)
    : super(const AsyncValue.data(null));

  // Sign in with email
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authService.signInWithEmail(email, password);
    });
  }

  // Register with email
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final credential = await _authService.registerWithEmail(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      // Create default services for new user
      await _firestoreService.createDefaultServices(credential.user!.uid);
    });
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final credential = await _authService.signInWithGoogle();

      // Check if new user and create default services
      if (credential.additionalUserInfo?.isNewUser ?? false) {
        await _firestoreService.createDefaultServices(credential.user!.uid);
      }
    });
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authService.resetPassword(email);
    });
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? pixKey,
    String? photoUrl,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = _authService.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (pixKey != null) updates['pixKey'] = pixKey;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      if (updates.isNotEmpty) {
        await _firestoreService.updateUser(user.uid, updates);

        // Also update Firebase Auth profile if name or photo changed
        if (name != null || photoUrl != null) {
          await user.updateProfile(displayName: name, photoURL: photoUrl);
        }
      }
    });
  }

  // Upload profile image
  Future<String> uploadProfileImage(dynamic imageFile) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final storageRef = FirebaseStorage.instance
        .ref()
        .child(AppConstants.profileImagesPath)
        .child('${user.uid}.jpg');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'uploaded_by': user.uid},
    );

    if (imageFile is File) {
      await storageRef.putFile(imageFile, metadata);
    } else if (imageFile is Uint8List) {
      await storageRef.putData(imageFile, metadata);
    } else {
      throw Exception('Tipo de arquivo não suportado');
    }

    final downloadUrl = await storageRef.getDownloadURL();
    await updateProfile(photoUrl: downloadUrl);
    return downloadUrl;
  }
}

// Auth ViewModel Provider
final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AsyncValue<void>>((ref) {
      final authService = ref.watch(authServiceProvider);
      final firestoreService = ref.watch(firestoreServiceProvider);
      return AuthViewModel(authService, firestoreService);
    });
