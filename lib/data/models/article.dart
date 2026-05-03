/// Artikel edukasi (statis, dimuat dari aset JSON).
class Article {
  const Article({
    required this.id,
    required this.title,
    required this.category,
    required this.readMinutes,
    required this.summary,
    required this.body,
    this.emoji,
    this.gradient,
  });

  final String id;
  final String title;
  final String category;
  final int readMinutes;
  final String summary;
  final String body;
  final String? emoji;
  final List<String>? gradient; // hex strings, e.g. ["FFB5C5", "FFD3DC"]

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        readMinutes: (json['readMinutes'] as num).toInt(),
        summary: json['summary'] as String,
        body: json['body'] as String,
        emoji: json['emoji'] as String?,
        gradient: (json['gradient'] as List<dynamic>?)?.cast<String>(),
      );
}
