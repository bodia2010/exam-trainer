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
    final lines = fullMarkdown.split('\n');
    final start = lines.indexWhere((l) => l.contains(anchor));
    if (start == -1) return '';
    return lines.sublist(start).join('\n');
  }
}
