class GuideOption {
  GuideOption({
    required this.id,
    required this.iconKey,
    required this.intention,
    required this.career,
    required this.description,
    required this.courses,
    required this.books,
    required this.competitions,
    required this.certificates,
  });

  final int id;
  final String iconKey;
  final String intention;
  final String career;
  final String description;
  final List<String> courses;
  final List<String> books;
  final List<String> competitions;
  final List<String> certificates;

  factory GuideOption.fromJson(Map<String, dynamic> json) {
    return GuideOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      iconKey: json['iconKey']?.toString() ?? '',
      intention: json['intention']?.toString() ?? '',
      career: json['career']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      courses: _stringList(json['courses']),
      books: _stringList(json['books']),
      competitions: _stringList(json['competitions']),
      certificates: _stringList(json['certificates']),
    );
  }

  static List<String> _stringList(dynamic value) {
    return (value as List<dynamic>? ?? const <dynamic>[])
        .map((dynamic item) => item.toString())
        .where((String item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }
}
