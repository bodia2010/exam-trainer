class DialogLine {
  final bool isPersonA;
  final String text;

  const DialogLine({required this.isPersonA, required this.text});
}

class SmalltalkAlternatives {
  final String label;
  final List<String> phrases;

  const SmalltalkAlternatives({required this.label, required this.phrases});
}

class SmalltalkExercise {
  final String id;
  final int number;
  final String stimulus;
  final List<DialogLine> dialogue;
  final List<SmalltalkAlternatives> alternatives;

  const SmalltalkExercise({
    required this.id,
    required this.number,
    required this.stimulus,
    required this.dialogue,
    required this.alternatives,
  });
}
