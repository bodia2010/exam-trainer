import 'package:flutter/material.dart';
import '../../l10n/strings.dart';
import 'legal_widgets.dart';

class ImpressumScreen extends StatelessWidget {
  const ImpressumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return LegalPage(
      title: s.impressumTitel,
      sections: [
        (s.impressumAngaben, s.impressumAngabenBody),
        (s.impressumVerantwortlich, 'Ihor Bondarenko\nlinguaproapps@gmail.com'),
        (s.impressumHaftung, s.impressumHaftungBody),
        (s.impressumUrheberrecht, s.impressumUrheberrechtBody),
        (s.impressumTelcHinweis, s.impressumTelcBody),
      ],
    );
  }
}
