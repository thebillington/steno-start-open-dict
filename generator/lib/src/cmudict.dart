import 'dart:io';

/// A single CMUdict phone, e.g. `AE1` or `K`.
class Phone {
  const Phone(this.raw);

  /// The raw phone as it appears in CMUdict, including any stress digit.
  final String raw;

  /// The phoneme without a stress digit, e.g. `AE` for `AE1`.
  String get phoneme {
    if (raw.isEmpty) {
      return raw;
    }
    final String last = raw[raw.length - 1];
    return last == '0' || last == '1' || last == '2'
        ? raw.substring(0, raw.length - 1)
        : raw;
  }

  /// The stress digit (`0`, `1`, `2`) or `null` for consonants.
  int? get stress {
    if (raw.isEmpty) {
      return null;
    }
    final String last = raw[raw.length - 1];
    return last == '0' || last == '1' || last == '2' ? int.parse(last) : null;
  }

  bool get isVowel => const <String>{
        'AA',
        'AE',
        'AH',
        'AO',
        'AW',
        'AY',
        'EH',
        'ER',
        'EY',
        'IH',
        'IY',
        'OW',
        'OY',
        'UH',
        'UW',
      }.contains(phoneme);

  @override
  String toString() => raw;
}

/// A word with one pronunciation. `key` is the lower-case CMUdict headword.
class Pronunciation {
  const Pronunciation(this.word, this.phones);

  final String word;
  final List<Phone> phones;

  String get phoneText => phones.join(' ');
}

/// A small CMUdict reader.
///
/// Only the first pronunciation of a word is needed, except for a documented
/// preference table for homographs such as "read" and "live". The dictionary
/// is used for pronunciation only; it contains no steno outlines.
class CmuDict {
  CmuDict._(this._variants);

  factory CmuDict.load(String path) {
    final Map<String, Map<int, List<Phone>>> variants =
        <String, Map<int, List<Phone>>>{};
    final List<String> lines = File(path).readAsLinesSync();
    for (final String line in lines) {
      if (line.isEmpty || line.startsWith(';;;')) {
        continue;
      }
      final int space = line.indexOf(' ');
      if (space <= 0) {
        continue;
      }
      final String head = line.substring(0, space);
      final String phones = line.substring(space + 1).trim();
      if (phones.isEmpty) {
        continue;
      }
      final RegExpMatch? match = RegExp(r'^(.*)\((\d+)\)$').firstMatch(head);
      final String word = match == null ? head : match.group(1)!;
      final int variant = match == null ? 1 : int.parse(match.group(2)!);
      variants.putIfAbsent(word, () => <int, List<Phone>>{}).putIfAbsent(
            variant,
            () => phones
                .split(RegExp(r'\s+'))
                .where((String p) => p.isNotEmpty)
                .map((String p) => Phone(p))
                .toList(growable: false),
          );
    }
    return CmuDict._(variants);
  }

  final Map<String, Map<int, List<Phone>>> _variants;

  /// Words that have more than one pronunciation in CMUdict.
  bool hasWord(String word) => _variants.containsKey(word.toLowerCase());

  /// Returns the preferred pronunciation, or the first available variant.
  ///
  /// [preferredVariant] is 1-based. A missing preferred variant falls back to
  /// the lowest-numbered variant so the build never silently drops a word.
  Pronunciation? pronunciation(String word, {int preferredVariant = 1}) {
    final String key = word.toLowerCase();
    final Map<int, List<Phone>>? byVariant = _variants[key];
    if (byVariant == null || byVariant.isEmpty) {
      return null;
    }
    final int variant = byVariant.containsKey(preferredVariant)
        ? preferredVariant
        : (byVariant.keys.toList()..sort()).first;
    return Pronunciation(key, byVariant[variant]!);
  }

  /// All variant numbers available for [word], sorted.
  List<int> variantsFor(String word) {
    final Map<int, List<Phone>>? byVariant = _variants[word.toLowerCase()];
    if (byVariant == null) {
      return const <int>[];
    }
    return byVariant.keys.toList()..sort();
  }

  /// The raw pronunciation text for a variant, for provenance.
  String? phoneText(String word, {int variant = 1}) {
    final Pronunciation? p = pronunciation(word, preferredVariant: variant);
    return p?.phoneText;
  }
}
