import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ParseService {
  ParseService._();
  static final instance = ParseService._();
  static const _timeout = Duration(seconds: 60);

  Future<String> convertPdf(Uint8List pdfBytes) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/convert'),
      headers: {
        'X-App-Secret': ApiConfig.secret,
        'Content-Type': 'application/octet-stream',
      },
      body: pdfBytes,
    ).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Ошибка конвертации ${res.statusCode}: ${res.body}');
    }
    return (jsonDecode(res.body)['markdown'] as String);
  }

  Future<List<dynamic>> parseSection(String markdown, String sectionType) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/parse'),
      headers: {
        'X-App-Secret': ApiConfig.secret,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'markdown': markdown, 'section_type': sectionType}),
    ).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Ошибка парсинга ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  String extractSection(String fullMarkdown, String anchor) {
    const knownAnchors = [
      'Hören Teil 1', 'Hören Teil 2', 'Hören Teil 3', 'Hören Teil 4',
      'Telefonnotiz', 'Sprachbausteine Teil 1', 'Sprachbausteine Teil 2',
      'Lesen Teil 1', 'Lesen Teil 2', 'Lesen Teil 3', 'Lesen Teil 4',
      'Schreiben', 'Sprechen',
    ];

    final lines = fullMarkdown.split('\n');
    final start = lines.indexWhere((l) => l.contains(anchor));
    if (start == -1) return '';

    // Stop at the first line that belongs to a DIFFERENT section
    final otherAnchors = knownAnchors.where((a) => a != anchor).toList();
    int end = lines.length;
    for (int i = start + 5; i < lines.length; i++) {
      final line = lines[i];
      // Section headers always contain "(вариант №" — use as disambiguator
      if (otherAnchors.any((a) => line.contains(a) && line.contains('вариант'))) {
        end = i;
        break;
      }
    }

    return lines.sublist(start, end).join('\n');
  }
}
