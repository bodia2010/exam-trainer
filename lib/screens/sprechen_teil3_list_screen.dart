import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/b2_beruf_teil3_data.dart';

class SprechenTeil3ListScreen extends StatelessWidget {
  const SprechenTeil3ListScreen({super.key});

  static const _accentColor = Color(0xFF6A1B9A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sprechen · Teil 3',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('Lösungswege diskutieren',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: b2BerufTeil3Exercises.length,
        itemBuilder: (context, index) {
          final ex = b2BerufTeil3Exercises[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Teil3Tile(
              number: ex.number,
              description: ex.description,
              onTap: () => context.push('/sprechen/teil3/${ex.id}'),
            ),
          );
        },
      ),
    );
  }
}

class _Teil3Tile extends StatelessWidget {
  final int number;
  final String description;
  final VoidCallback onTap;

  const _Teil3Tile(
      {required this.number, required this.description, required this.onTap});

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
                      child: Center(
                        child: Text('$number',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _accentColor)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(description,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A237E),
                              height: 1.4),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
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
