class ScanItem {
  final String content;
  final String format;
  final DateTime timestamp;

  ScanItem({
    required this.content,
    required this.format,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        'format': format,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ScanItem.fromJson(Map<String, dynamic> json) => ScanItem(
        content: json['content'] as String? ?? '',
        format: json['format'] as String? ?? 'unknown',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}