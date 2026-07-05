class ParsedCourse {
  final String id;
  final String title;
  final String sourceFilename;
  final DateTime parsedAt;
  final Map<String, List<dynamic>> sections;

  const ParsedCourse({
    required this.id,
    required this.title,
    required this.sourceFilename,
    required this.parsedAt,
    required this.sections,
  });

  factory ParsedCourse.fromJson(Map<String, dynamic> j) => ParsedCourse(
        id: j['id'] as String,
        title: j['title'] as String,
        sourceFilename: j['source_filename'] as String,
        parsedAt: DateTime.parse(j['parsed_at'] as String),
        sections: (j['sections'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as List<dynamic>),
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'source_filename': sourceFilename,
        'parsed_at': parsedAt.toIso8601String(),
        'sections': sections,
      };
}

const sectionLabels = <String, String>{
  'hoeren_teil1':         'Hören Teil 1',
  'hoeren_teil2':         'Hören Teil 2',
  'telefonnotiz':         'Hören + Schreiben',
  'sprachbausteine_teil1': 'Sprachbausteine Teil 1',
};
