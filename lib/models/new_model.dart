
class News {
  final String title;
  final String summary;
  final String source;
  final String date;

  News(
      {required this.title,
      required this.summary,
      required this.source,
      required this.date});

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      title: json['title'],
      summary: json['summary'],
      source: json['source'],
      date: json['date'],
    );
  }
}
