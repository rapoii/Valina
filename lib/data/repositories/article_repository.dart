import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../models/article.dart';

/// Repository artikel edukasi.
///
/// Konten artikel dimuat dari asset JSON (statis), sedangkan bookmark per user
/// disimpan di Firestore di `users/{uid}/settings/bookmarks`.
class ArticleRepository {
  ArticleRepository({required this.uid, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _assetPath = 'assets/data/articles.json';

  final String uid;
  final FirebaseFirestore _firestore;

  List<Article>? _cache;

  DocumentReference<Map<String, dynamic>> get _bookmarkDoc => _firestore
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('bookmarks');

  Future<List<Article>> all() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final data = jsonDecode(raw) as List<dynamic>;
    _cache = data
        .map((e) => Article.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return _cache!;
  }

  Future<Article?> byId(String id) async {
    final list = await all();
    for (final a in list) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<List<Article>> byCategory(String category) async {
    final list = await all();
    return list.where((a) => a.category == category).toList();
  }

  Future<List<String>> categories() async {
    final list = await all();
    final set = <String>{};
    for (final a in list) {
      set.add(a.category);
    }
    return set.toList();
  }

  /// Stream daftar id artikel yang di-bookmark.
  Stream<Set<String>> watchBookmarks() {
    return _bookmarkDoc.snapshots().map((snap) {
      final data = snap.data();
      final raw = data?['ids'];
      if (raw is List) return raw.cast<String>().toSet();
      return <String>{};
    });
  }

  Future<Set<String>> fetchBookmarks() async {
    final snap = await _bookmarkDoc.get();
    final raw = snap.data()?['ids'];
    if (raw is List) return raw.cast<String>().toSet();
    return <String>{};
  }

  Future<void> toggleBookmark(String id) async {
    final current = await fetchBookmarks();
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    await _bookmarkDoc.set({'ids': current.toList()}, SetOptions(merge: true));
  }
}
