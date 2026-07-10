class Favorite {
  final String id;
  final String title;
  final String subtitle;
  final String route;
  /// Null for fixed content not tied to an imported PDF (the Sprechen
  /// bank). Set for anything under an imported course, so the bookmark
  /// can be cascade-deleted when that course is removed — otherwise it'd
  /// be a dead link into a course that no longer exists.
  final String? courseId;
  final DateTime addedAt;

  const Favorite({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.courseId,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'route': route,
        'courseId': courseId,
        'addedAt': addedAt.toIso8601String(),
      };

  factory Favorite.fromJson(Map<String, dynamic> j) => Favorite(
        id: j['id'] as String,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        route: j['route'] as String,
        courseId: j['courseId'] as String?,
        addedAt: DateTime.parse(j['addedAt'] as String),
      );
}
