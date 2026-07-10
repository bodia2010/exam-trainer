import 'package:flutter/material.dart';
import '../../l10n/strings.dart';
import 'legal_widgets.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return LegalPage(
      title: s.nutzungTitel,
      sections: [
        (s.nutzung1, s.nutzung1Body),
        (s.nutzung2, s.nutzung2Body),
        (s.nutzung3, s.nutzung3Body),
        (s.nutzung4, s.nutzung4Body),
        (s.nutzung5, s.nutzung5Body),
        (s.nutzung6, s.nutzung6Body),
        (s.nutzung7, s.nutzung7Body),
        (s.nutzung8, 'linguaproapps@gmail.com'),
      ],
    );
  }
}
