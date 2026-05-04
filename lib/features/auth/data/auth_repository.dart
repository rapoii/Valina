import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

/// Wrapper FirebaseAuth + GoogleSignIn dengan API yang ramah pemanggil.
///
/// Menerjemahkan `FirebaseAuthException` ke `AuthFailure` dengan pesan
/// bahasa Indonesia, supaya layer presentation tidak perlu peduli kode error.
class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('Login gagal. Coba lagi.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_translate(e));
    }
  }

  Future<User> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('Pendaftaran gagal. Coba lagi.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_translate(e));
    }
  }

  Future<User> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Di web, FirebaseAuth menyediakan flow popup native.
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        final credential = await _auth.signInWithPopup(provider);
        final user = credential.user;
        if (user == null) {
          throw const AuthFailure('Login Google dibatalkan.');
        }
        return user;
      }

      // Mobile: pakai google_sign_in untuk dapat ID token + access token.
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthFailure('Login Google dibatalkan.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        throw const AuthFailure('Login Google gagal. Coba lagi.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_translate(e));
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure('Login Google gagal: $e');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_translate(e));
    }
  }

  /// Hapus akun permanen. Memerlukan re-autentikasi terlebih dahulu.
  /// [password] diisi untuk email user, null untuk Google user.
  Future<void> deleteAccount({String? password}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw const AuthFailure('Tidak ada user yang login.');

      // Re-authenticate sesuai provider.
      final providers = user.providerData.map((p) => p.providerId).toList();
      if (providers.contains('google.com')) {
        // Google: sign in ulang untuk dapat credential baru.
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw const AuthFailure('Re-autentikasi dibatalkan.');
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        // Email/password: pakai password yang diberikan.
        if (password == null || password.isEmpty) {
          throw const AuthFailure('Password diperlukan untuk menghapus akun.');
        }
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }

      await user.delete();
      if (!kIsWeb) {
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
      }
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_translate(e));
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure('Hapus akun gagal: $e');
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // ignore — user mungkin tidak login via Google.
      }
    }
    await _auth.signOut();
  }

  String _translate(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan.';
      case 'user-not-found':
        return 'Akun tidak ditemukan.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Coba login.';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter).';
      case 'operation-not-allowed':
        return 'Metode login ini belum diaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      default:
        return e.message ?? 'Terjadi kesalahan (${e.code}).';
    }
  }
}

/// Exception khusus auth dengan pesan yang sudah bisa langsung ditampilkan.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
