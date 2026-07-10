import 'package:flutter/material.dart';

/// Shared scaffold for the legal pages (Impressum, Datenschutz,
/// Nutzungsbedingungen): an app-bar title plus a scrollable list of
/// (section title, body) pairs.
class LegalPage extends StatelessWidget {
  final String title;
  final List<(String, String)> sections;

  const LegalPage({super.key, required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (heading, body) in sections) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
              Text(
                body,
                style: const TextStyle(
                    fontSize: 14, height: 1.6, color: Colors.black87),
              ),
              const SizedBox(height: 24),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
