import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parsed_course.dart';

class CourseStorage {
  CourseStorage._();
  static final instance = CourseStorage._();
  static const _key = 'course_ids';

  Future<Directory> get _dir async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/courses');
    if (!d.existsSync()) d.createSync();
    return d;
  }

  Future<void> save(ParsedCourse course) async {
    final dir = await _dir;
    await File('${dir.path}/${course.id}.json')
        .writeAsString(jsonEncode(course.toJson()), flush: true);
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    if (!ids.contains(course.id)) {
      await prefs.setStringList(_key, [...ids, course.id]);
    }
  }

  Future<List<ParsedCourse>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    final dir = await _dir;
    final result = <ParsedCourse>[];
    for (final id in ids) {
      final f = File('${dir.path}/$id.json');
      if (f.existsSync()) {
        result.add(ParsedCourse.fromJson(
            jsonDecode(await f.readAsString()) as Map<String, dynamic>));
      }
    }
    return result;
  }

  Future<void> delete(String id) async {
    final dir = await _dir;
    final f = File('${dir.path}/$id.json');
    if (f.existsSync()) f.deleteSync();
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_key) ?? [])..remove(id);
    await prefs.setStringList(_key, ids);
  }
}
