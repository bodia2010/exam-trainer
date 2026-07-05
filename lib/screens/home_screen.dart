import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/parsed_course.dart';
import '../services/course_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ParsedCourse> _courses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final courses = await CourseStorage.instance.loadAll();
      if (mounted) setState(() { _courses = courses; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _delete(ParsedCourse course) async {
    await CourseStorage.instance.delete(course.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00838F),
        foregroundColor: Colors.white,
        title: const Text('Exam Trainer'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? _empty(context)
              : _list(context),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00838F),
        foregroundColor: Colors.white,
        onPressed: () => context.push('/import'),
        icon: const Icon(Icons.upload_file),
        label: const Text('Импортировать PDF'),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_as_pdf_outlined, size: 72, color: Color(0xFFBDBDBD)),
          const SizedBox(height: 16),
          const Text('Нет импортированных курсов',
              style: TextStyle(fontSize: 16, color: Color(0xFF757575))),
          const SizedBox(height: 8),
          const Text('Загрузите PDF с упражнениями',
              style: TextStyle(fontSize: 14, color: Color(0xFFBDBDBD))),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00838F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => context.push('/import'),
            icon: const Icon(Icons.upload_file),
            label: const Text('Выбрать PDF'),
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _courses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final course = _courses[i];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE0F7FA),
              child: Icon(Icons.menu_book, color: Color(0xFF00838F)),
            ),
            title: Text(course.title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${course.sections.values.fold(0, (s, v) => s + v.length)} вариантов · '
              '${_formatDate(course.parsedAt)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/course/${course.id}'),
            onLongPress: () => _confirmDelete(context, course),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, ParsedCourse course) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить курс?'),
        content: Text(course.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () { Navigator.pop(context); _delete(course); },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
