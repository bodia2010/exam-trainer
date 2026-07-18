import 'dart:math';

import 'package:flutter/material.dart';

import '../../../data/b2_beruf_smalltalk_data.dart';
import '../../../data/b2_beruf_sprechen_data.dart';
import '../../../data/b2_beruf_teil3_data.dart';
import '../../../models/parsed_course.dart';
import '../../../widgets/course_load_state.dart';

enum ProbePruefungStatus { loading, content, notFound, error }

class ProbeExamPart {
  const ProbeExamPart({
    required this.label,
    required this.subtitle,
    required this.route,
    required this.color,
    required this.icon,
    required this.minutes,
  });

  final String label;
  final String subtitle;
  final String route;
  final Color color;
  final IconData icon;
  final int minutes;
}

typedef ProbeExamPlanBuilder =
    List<ProbeExamPart> Function(ParsedCourse course, Random random);

class ProbePruefungController extends ChangeNotifier {
  ProbePruefungController({
    required this.loader,
    ProbeExamPlanBuilder? planBuilder,
    Random Function()? randomFactory,
  }) : _planBuilder = planBuilder ?? buildProbeExamPlan,
       _randomFactory = randomFactory ?? Random.new;

  final CourseLoader loader;
  final ProbeExamPlanBuilder _planBuilder;
  final Random Function() _randomFactory;
  ProbePruefungStatus _status = ProbePruefungStatus.loading;
  ParsedCourse? _course;
  List<ProbeExamPart> _parts = const [];
  int _operation = 0;
  bool _disposed = false;

  ProbePruefungStatus get status => _status;
  ParsedCourse? get course => _course;
  List<ProbeExamPart> get parts => List.unmodifiable(_parts);
  int get totalMinutes => _parts.fold(0, (sum, part) => sum + part.minutes);

  Future<void> load(String courseId) async {
    final operation = ++_operation;
    _course = null;
    _parts = const [];
    _setStatus(ProbePruefungStatus.loading);
    try {
      final courses = await loader();
      if (_disposed || operation != _operation) return;
      final course = courses.where((item) => item.id == courseId).firstOrNull;
      if (course == null) {
        _setStatus(ProbePruefungStatus.notFound);
        return;
      }
      final parts = _planBuilder(course, _randomFactory());
      if (_disposed || operation != _operation) return;
      _course = course;
      _parts = List.unmodifiable(parts);
      _setStatus(ProbePruefungStatus.content);
    } catch (_) {
      if (_disposed || operation != _operation) return;
      _course = null;
      _parts = const [];
      _setStatus(ProbePruefungStatus.error);
    }
  }

  bool regenerate() {
    final course = _course;
    if (_disposed || course == null) return false;
    try {
      _parts = List.unmodifiable(_planBuilder(course, _randomFactory()));
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _setStatus(ProbePruefungStatus status) {
    if (_disposed) return;
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _operation++;
    super.dispose();
  }
}

const _minutesByType = <String, int>{
  'hoeren_teil1': 5,
  'hoeren_teil2': 5,
  'hoeren_teil3': 5,
  'hoeren_teil4': 5,
  'lesen_teil1': 11,
  'lesen_teil2': 12,
  'lesen_teil3': 11,
  'lesen_teil4': 11,
  'beschwerde': 20,
  'telefonnotiz': 5,
  'sprachbausteine_teil1': 17,
  'sprachbausteine_teil2': 18,
};

List<ProbeExamPart> buildProbeExamPlan(ParsedCourse course, Random random) {
  final parts = <ProbeExamPart>[];
  for (final entry in sectionMeta.entries) {
    final type = entry.key;
    final variants = course.sections[type] ?? const [];
    if (variants.isEmpty) continue;
    final index = random.nextInt(variants.length);
    final variant = variants[index] as Map<String, dynamic>;
    final variantNumber = variant['variant_number'] ?? (index + 1);
    parts.add(
      ProbeExamPart(
        label: entry.value.label,
        subtitle: 'Variante $variantNumber',
        route: '/course/${course.id}/$type/$index',
        color: entry.value.color,
        icon: entry.value.icon,
        minutes: _minutesByType[type] ?? 10,
      ),
    );
  }

  const sprechenColor = Color(0xFF6A1B9A);
  final sprechen1 =
      b2BerufSprechenExercises[random.nextInt(b2BerufSprechenExercises.length)];
  final sprechen2 =
      b2BerufSmalltalkExercises[random.nextInt(
        b2BerufSmalltalkExercises.length,
      )];
  final sprechen3 =
      b2BerufTeil3Exercises[random.nextInt(b2BerufTeil3Exercises.length)];
  parts.addAll([
    ProbeExamPart(
      label: 'Sprechen Teil 1',
      subtitle: sprechen1.topic,
      route: '/sprechen/b2-beruf/teil1/${sprechen1.id}',
      color: sprechenColor,
      icon: Icons.record_voice_over_rounded,
      minutes: 3,
    ),
    ProbeExamPart(
      label: 'Sprechen Teil 2',
      subtitle: 'Thema ${sprechen2.number}',
      route: '/sprechen/b2-beruf/teil2/${sprechen2.id}',
      color: sprechenColor,
      icon: Icons.forum_rounded,
      minutes: 3,
    ),
    ProbeExamPart(
      label: 'Sprechen Teil 3',
      subtitle: 'Situation ${sprechen3.number}',
      route: '/sprechen/b2-beruf/teil3/${sprechen3.id}',
      color: sprechenColor,
      icon: Icons.groups_rounded,
      minutes: 10,
    ),
  ]);
  return parts;
}
