class Vocabulary {
  final int id;
  final String word;
  final String meaning;

  Vocabulary({
    required this.id,
    required this.word,
    required this.meaning,
  });

  factory Vocabulary.fromCsv(List<String> fields) {
    return Vocabulary(
      id: int.parse(fields[0]),
      word: fields[1],
      meaning: fields[2],
    );
  }

  @override
  String toString() => '$word: $meaning';
}
