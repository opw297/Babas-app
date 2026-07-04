class TafsirEntry {
  final int surahNumber;
  final String title;
  final String content;
  final String source;

  const TafsirEntry({
    required this.surahNumber,
    required this.title,
    required this.content,
    this.source = 'Dataset lokal',
  });

  factory TafsirEntry.fromJson(Map<String, dynamic> json) {
    return TafsirEntry(
      surahNumber: _parseInt(json['surahNumber'] ?? json['number'] ?? json['surah'] ?? 0),
      title: json['title']?.toString() ?? 'Tafsir',
      content: json['content']?.toString() ?? json['text']?.toString() ?? '',
      source: json['source']?.toString() ?? 'Dataset lokal',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
