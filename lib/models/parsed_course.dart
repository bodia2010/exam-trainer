import 'package:flutter/material.dart';

/// Visual identity of a section — colors/icons ported from deutch-lernen.
class SectionMeta {
  final String label; // e.g. "Lesen Teil 1"
  final String taskName; // German task name, e.g. "Zuordnungsaufgabe"
  final Color color;
  final IconData icon;
  const SectionMeta({
    required this.label,
    required this.taskName,
    required this.color,
    required this.icon,
  });
}

const sectionMeta = <String, SectionMeta>{
  'lesen_teil1': SectionMeta(
    label: 'Lesen Teil 1',
    taskName: 'Zuordnungsaufgabe',
    color: Color(0xFF2E7D32),
    icon: Icons.swap_horiz_rounded,
  ),
  'lesen_teil2': SectionMeta(
    label: 'Lesen Teil 2',
    taskName: 'Leseverstehen',
    color: Color(0xFF1565C0),
    icon: Icons.checklist_rounded,
  ),
  'lesen_teil3': SectionMeta(
    label: 'Lesen Teil 3',
    taskName: 'Zuordnung: Forum',
    color: Color(0xFF7B1FA2),
    icon: Icons.forum_rounded,
  ),
  'lesen_teil4': SectionMeta(
    label: 'Lesen Teil 4',
    taskName: 'Protokoll: Multiple Choice',
    color: Color(0xFF00695C),
    icon: Icons.description_rounded,
  ),
  'beschwerde': SectionMeta(
    label: 'Beschwerde',
    taskName: 'Briefe + Musterantwort',
    color: Color(0xFFC62828),
    icon: Icons.drafts_rounded,
  ),
  'sprachbausteine_teil1': SectionMeta(
    label: 'Sprachbausteine Teil 1',
    taskName: 'Wortliste-Lücken',
    color: Color(0xFF1565C0),
    icon: Icons.spellcheck_rounded,
  ),
  'sprachbausteine_teil2': SectionMeta(
    label: 'Sprachbausteine Teil 2',
    taskName: 'Lücken mit Optionen',
    color: Color(0xFF5E35B1),
    icon: Icons.edit_note_rounded,
  ),
  'telefonnotiz': SectionMeta(
    label: 'Hören + Schreiben',
    taskName: 'Telefonnotiz',
    color: Color(0xFFE65100),
    icon: Icons.phone_in_talk_rounded,
  ),
  'hoeren_teil1': SectionMeta(
    label: 'Hören Teil 1',
    taskName: 'Dialoge: R/F + Auswahl',
    color: Color(0xFF00838F),
    icon: Icons.headphones_rounded,
  ),
  'hoeren_teil2': SectionMeta(
    label: 'Hören Teil 2',
    taskName: 'Aussagen zuordnen',
    color: Color(0xFF0277BD),
    icon: Icons.hearing_rounded,
  ),
  'hoeren_teil3': SectionMeta(
    label: 'Hören Teil 3',
    taskName: 'Gespräch: Multiple Choice',
    color: Color(0xFF6A1B9A),
    icon: Icons.record_voice_over_rounded,
  ),
  'hoeren_teil4': SectionMeta(
    label: 'Hören Teil 4',
    taskName: 'Ansagen: Multiple Choice',
    color: Color(0xFFAD1457),
    icon: Icons.voicemail_rounded,
  ),
};

class ParsedCourse {
  final String id;
  final String title;
  final String sourceFilename;
  final DateTime parsedAt;
  final Map<String, List<dynamic>> sections;
  // Which exam this course was imported as — discovery/parsing only has
  // prompts for telc/Beruf/B2 today, but storing the profile now means a
  // course already carries the right routing info once other profiles
  // (Goethe, Allgemein, Pflege, ...) ship, instead of every existing
  // course silently being reinterpreted as whatever ships next.
  final String examProvider;
  final String examCourseType;
  final String examLevel;

  const ParsedCourse({
    required this.id,
    required this.title,
    required this.sourceFilename,
    required this.parsedAt,
    required this.sections,
    this.examProvider = 'telc',
    this.examCourseType = 'Beruf',
    this.examLevel = 'B2',
  });

  factory ParsedCourse.fromJson(Map<String, dynamic> j) => ParsedCourse(
    id: j['id'] as String,
    title: j['title'] as String,
    sourceFilename: j['source_filename'] as String,
    parsedAt: DateTime.parse(j['parsed_at'] as String),
    sections: (j['sections'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as List<dynamic>),
    ),
    examProvider: j['exam_provider'] as String? ?? 'telc',
    examCourseType: j['exam_course_type'] as String? ?? 'Beruf',
    examLevel: j['exam_level'] as String? ?? 'B2',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'source_filename': sourceFilename,
    'parsed_at': parsedAt.toIso8601String(),
    'sections': sections,
    'exam_provider': examProvider,
    'exam_course_type': examCourseType,
    'exam_level': examLevel,
  };
}

const sectionLabels = <String, String>{
  'lesen_teil1': 'Lesen Teil 1',
  'lesen_teil2': 'Lesen Teil 2',
  'lesen_teil3': 'Lesen Teil 3',
  'lesen_teil4': 'Lesen Teil 4',
  'beschwerde': 'Beschwerde',
  'sprachbausteine_teil1': 'Sprachbausteine Teil 1',
  'sprachbausteine_teil2': 'Sprachbausteine Teil 2',
  'telefonnotiz': 'Hören + Schreiben',
  'hoeren_teil1': 'Hören Teil 1',
  'hoeren_teil2': 'Hören Teil 2',
  'hoeren_teil3': 'Hören Teil 3',
  'hoeren_teil4': 'Hören Teil 4',
};
