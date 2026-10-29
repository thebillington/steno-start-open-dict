import 'stroke.dart';

/// A word -> stroke dictionary that indexes strokes by their
/// notation-independent [Stroke.signature].
///
/// Every stroke is parsed eagerly, so an invalid entry or two words sharing the
/// same chord are rejected at construction time.
///
/// ```dart
/// final dict = StenoDictionary(<String, String>{
///   'cat': 'KAT',
///   'at': 'AT',
/// });
/// dict.strokeForWord('cat');          // 'KAT'
/// dict.wordForStroke('KAT');          // 'cat'
/// dict.wordForStroke('kat');          // 'cat' (case-insensitive)
/// dict.wordForSignature('2|7|18');    // 'cat'
/// dict.describeWord('cat');           // 'cat: KAT (left K · vowel A · right T)'
/// dict.allWords;                      // ['at', 'cat']
/// ```
class StenoDictionary {
  /// Builds a dictionary from `word -> stroke` [entries].
  ///
  /// Throws an [ArgumentError] if a word is empty or if two different words
  /// resolve to the same chord, and a [FormatException] if a stroke is invalid.
  StenoDictionary(Map<String, String> entries) {
    final List<String> words = entries.keys.toList()..sort();
    for (final String word in words) {
      if (word.trim().isEmpty) {
        throw ArgumentError.value(
          word,
          'entries',
          'Word keys must not be empty.',
        );
      }

      final String source = entries[word]!;
      final Stroke stroke;
      try {
        stroke = Stroke.parse(source);
      } on FormatException catch (error) {
        throw FormatException(
          'Invalid stroke "$source" for word "$word": ${error.message}',
          source,
        );
      }

      final String? clash = _wordBySignature[stroke.signature];
      if (clash != null) {
        throw ArgumentError(
          'Stroke collision: "$word" and "$clash" both use '
          '"${stroke.format()}" (signature ${stroke.signature}).',
        );
      }

      _strokeByWord[word] = stroke;
      _wordBySignature[stroke.signature] = word;
    }

    _allWords = List<String>.unmodifiable(words);
  }

  /// An empty dictionary.
  StenoDictionary.empty() : _allWords = const <String>[];

  final Map<String, Stroke> _strokeByWord = <String, Stroke>{};
  final Map<String, String> _wordBySignature = <String, String>{};
  late final List<String> _allWords;

  /// All known words, sorted alphabetically.
  List<String> get allWords => _allWords;

  /// Number of words in the dictionary.
  int get length => _allWords.length;

  /// Whether the dictionary has no words.
  bool get isEmpty => _allWords.isEmpty;

  /// Whether [word] is in the dictionary.
  bool containsWord(String word) => _strokeByWord.containsKey(word);

  /// The canonical stroke for [word], or `null` if the word is unknown.
  String? strokeForWord(String word) => _strokeByWord[word]?.format();

  /// The chord for [word], or `null` if the word is unknown.
  Stroke? strokeObjectForWord(String word) => _strokeByWord[word];

  /// The signature of [word]'s chord, or `null` if the word is unknown.
  String? signatureForWord(String word) => _strokeByWord[word]?.signature;

  /// The word whose chord has [signature], or `null` if there is none.
  ///
  /// Signatures are the canonical form produced by [Stroke.signature], so the
  /// comparison is independent of how the stroke was written.
  String? wordForSignature(String signature) {
    final String key = signature.trim();
    if (key.isEmpty) {
      return null;
    }
    return _wordBySignature[key];
  }

  /// The word written by [stroke], or `null` if the stroke is invalid or
  /// unknown.
  ///
  /// Any notation for the same chord works: `KAT`, `kat`, and ` KAT ` all find
  /// the same word.
  String? wordForStroke(String stroke) {
    final Stroke? parsed = Stroke.tryParse(stroke);
    if (parsed == null) {
      return null;
    }
    return _wordBySignature[parsed.signature];
  }

  /// A description of [word]'s stroke, or `null` if the word is unknown.
  ///
  /// Format: `word: STROKE (left K · vowel A · right T)`.
  String? describeWord(String word) {
    final Stroke? stroke = _strokeByWord[word];
    if (stroke == null) {
      return null;
    }
    return '$word: ${stroke.format()} (${stroke.describe()})';
  }

  /// Every entry, ordered alphabetically by word.
  Map<String, String> get entries => Map<String, String>.unmodifiable(
        <String, String>{
          for (final String word in _allWords)
            word: _strokeByWord[word]!.format(),
        },
      );

  @override
  String toString() => 'StenoDictionary(${_allWords.length} words)';
}
