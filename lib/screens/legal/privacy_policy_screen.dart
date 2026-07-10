import 'package:flutter/material.dart';
import '../../l10n/strings.dart';
import 'legal_widgets.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return LegalPage(
      title: s.datenschutzTitel,
      sections: [
        (s.datenschutz1, s.datenschutz1Body),
        (s.datenschutz2, s.datenschutz2Body),
        (s.datenschutz3, s.datenschutz3Body),
        (s.datenschutz4, s.datenschutz4Body),
        (s.datenschutz5, s.datenschutz5Body),
        (s.datenschutz6, s.datenschutz6Body),
        (s.datenschutz7, s.datenschutz7Body),
        (s.datenschutz8, 'linguaproapps@gmail.com'),
        (s.datenschutz9, s.datenschutz9Body),
      ],
    );
  }
}
