class TranslationItem {
  final String id;
  final String sourceText;
  final String translatedText;
  final DateTime timestamp;
  final bool isFavorite;
  final DateTime? favoritedAt;

  TranslationItem({
    required this.id,
    required this.sourceText,
    required this.translatedText,
    required this.timestamp,
    required this.isFavorite,
    this.favoritedAt,
  });

  // Get the timestamp to display (favorited time if available, otherwise translation time)
  DateTime get displayTimestamp => favoritedAt ?? timestamp;

  factory TranslationItem.fromJson(Map<String, dynamic> json) {
    return TranslationItem(
      id: json['_id'] ?? '',
      sourceText: json['original_text'] ?? '',
      translatedText: json['translated_text'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isFavorite: json['is_favorite'] ?? false,
      favoritedAt: json['favorited_at'] != null 
          ? DateTime.tryParse(json['favorited_at']) 
          : null,
    );
  }
}
