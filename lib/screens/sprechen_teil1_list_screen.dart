import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SprechenTeil1ListScreen extends StatelessWidget {
  const SprechenTeil1ListScreen({super.key});

  static const _accentColor = Color(0xFF6A1B9A);

  static const _topics = [
    (id: 'v1', topic: 'Arbeitgeber'),
    (id: 'v2', topic: 'Gutes Arbeitsumfeld'),
    (id: 'v3', topic: 'Berufswahl'),
    (id: 'v4', topic: 'Berufliches Vorbild'),
    (id: 'v5', topic: 'Vorgehen bei der Arbeitssuche'),
    (id: 'v6', topic: 'Bewerbungsgespräch'),
    (id: 'v7', topic: 'Produkt / Dienstleistung'),
    (id: 'v8', topic: 'Selbstständigkeit / Geschäftsidee'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sprechen · Teil 1',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('Monolog · 2 Minuten',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _topics.length,
        itemBuilder: (context, index) {
          final entry = _topics[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TopicTile(
              topic: entry.topic,
              onTap: () => context.push('/sprechen/b2-beruf/teil1/${entry.id}'),
            ),
          );
        },
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final String topic;
  final VoidCallback onTap;

  const _TopicTile({required this.topic, required this.onTap});

  static const _accentColor = Color(0xFF6A1B9A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(width: 4, color: _accentColor),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.record_voice_over,
                          color: _accentColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(topic,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A237E))),
                          const SizedBox(height: 3),
                          Text('Drücken Sie Play und sprechen Sie 2 Minuten',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: Colors.grey[400], size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
