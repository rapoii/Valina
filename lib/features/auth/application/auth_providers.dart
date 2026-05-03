import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Stream user state. Emit `null` saat belum login / sudah logout.
final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

/// User saat ini (sync, dari snapshot stream). Null kalau belum login.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});
