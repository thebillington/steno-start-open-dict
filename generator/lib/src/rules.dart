import 'package:steno_engine/steno_engine.dart';

import 'cmudict.dart';

/// A candidate single-stroke outline for one word.
class RuleCandidate {
  const RuleCandidate({
    required this.outline,
    required this.signature,
    required this.keyIds,
    required this.variant,
    required this.mergedEarlier,
    required this.targetPhone,
    required this.onsetPhones,
    required this.codaPhones,
  });

  final String outline;
  final String signature;
  final Set<int> keyIds;

  /// `base`, `merged`, `star` or `tag-...`.
  final String variant;

  /// Whether earlier unstressed vowels were folded into the vowel group.
  final bool mergedEarlier;

  /// The stressed vowel phoneme used as the nucleus.
  final String targetPhone;

  /// Onset consonant phonemes, in pronunciation order.
  final List<String> onsetPhones;

  /// Coda consonant phonemes, in pronunciation order.
  final List<String> codaPhones;

  bool get isBase => variant == 'base';
}

/// Rule-derived outlines from CMUdict pronunciation and the open Stenotype
/// chart.
///
/// The engine writes one chord per stroke. The rule keeps the last primary
/// stressed vowel as the nucleus and folds the surrounding consonants into the
/// onset/coda; a merged variant is available for words such as `along` where
/// dropping an initial schwa would collide with another word.
class RuleEngine {
  RuleEngine(this.cmu);

  final CmuDict cmu;

  /// Homographs whose first CMUdict pronunciation is not the sense used in
  /// the 500-word list. Values are 1-based CMUdict variant numbers.
  static const Map<String, int> preferredVariants = <String, int>{
    'live': 2, // verb /lɪv/, not adjective /laɪv/
    'read': 2, // present /riːd/, not past /rɛd/
    'lead': 2, // verb /liːd/, not the metal
    'close': 2, // verb /kloʊz/, not the adjective
    'use': 2, // verb /juːz/
  };

  /// All distinct, faithful candidate strokes for [word], in deterministic
  /// priority order: plain rule, merged-vowel rule, then documented
  /// disambiguation tags.
  List<RuleCandidate> candidatesFor(String word) {
    final Pronunciation? pronunciation = cmu.pronunciation(
      word,
      preferredVariant: preferredVariants[word.toLowerCase()] ?? 1,
    );
    if (pronunciation == null) {
      return const <RuleCandidate>[];
    }

    final List<RuleCandidate> candidates = <RuleCandidate>[];
    final Set<String> seen = <String>{};

    for (final bool merge in <bool>[false, true]) {
      final _Built? built = _build(
        word: word,
        phones: pronunciation.phones,
        spelling: _spellingOf(word),
        mergeEarlier: merge,
        applySilentLetters: true,
      );
      if (built == null) {
        continue;
      }

      // First the plain/merged stroke. Then add one unused star, followed by
      // single right-hand tags. Tags are only a last resort and are recorded
      // in provenance.
      final List<MapEntry<String, Set<int>>> variants =
          <MapEntry<String, Set<int>>>[
        MapEntry<String, Set<int>>(merge ? 'merged' : 'base', built.keyIds),
      ];
      if (!built.keyIds.contains(_star)) {
        variants.add(
          MapEntry<String, Set<int>>('${merge ? 'merged' : 'base'}+star', <int>{
            ...built.keyIds,
            _star,
          }),
        );
      }
      for (final int tag in rightTagOrder) {
        if (built.keyIds.contains(tag)) {
          continue;
        }
        variants.add(
          MapEntry<String, Set<int>>(
            '${merge ? 'merged' : 'base'}+tag-${_letter(tag)}',
            <int>{...built.keyIds, tag},
          ),
        );
      }

      for (final MapEntry<String, Set<int>> entry in variants) {
        final _Built? candidate = _build(
          word: word,
          phones: pronunciation.phones,
          spelling: _spellingOf(word),
          mergeEarlier: merge,
          applySilentLetters: true,
          extraKeys: entry.value.difference(built.keyIds),
          variantOverride: entry.key,
        );
        if (candidate == null) {
          continue;
        }
        if (!seen.add(candidate.signature)) {
          continue;
        }
        candidates.add(
          RuleCandidate(
            outline: candidate.outline,
            signature: candidate.signature,
            keyIds: candidate.keyIds,
            variant: candidate.variant,
            mergedEarlier: merge,
            targetPhone: candidate.targetPhone,
            onsetPhones: candidate.onsetPhones,
            codaPhones: candidate.codaPhones,
          ),
        );
      }
    }

    return candidates;
  }

  /// Builds one stroke from a phone subset. Used for the optional two-stroke
  /// expansions in `data/multi_stroke.json`.
  RuleCandidate? buildPart(
    String spelling,
    List<Phone> phones, {
    required String variant,
  }) {
    final _Built? built = _build(
      word: spelling,
      phones: phones,
      spelling: _spellingOf(spelling),
      mergeEarlier: false,
      applySilentLetters: false,
      variantOverride: variant,
    );
    if (built == null) {
      return null;
    }
    return RuleCandidate(
      outline: built.outline,
      signature: built.signature,
      keyIds: built.keyIds,
      variant: built.variant,
      mergedEarlier: false,
      targetPhone: built.targetPhone,
      onsetPhones: built.onsetPhones,
      codaPhones: built.codaPhones,
    );
  }

  _Built? _build({
    required String word,
    required List<Phone> phones,
    required String spelling,
    required bool mergeEarlier,
    required bool applySilentLetters,
    Set<int> extraKeys = const <int>{},
    String? variantOverride,
  }) {
    if (phones.isEmpty) {
      return null;
    }

    final List<int> vowelIndices = <int>[
      for (int i = 0; i < phones.length; i++)
        if (phones[i].isVowel) i,
    ];
    if (vowelIndices.isEmpty) {
      return null;
    }

    final List<int> primary = <int>[
      for (final int i in vowelIndices)
        if (phones[i].stress == 1) i,
    ];
    final List<int> secondary = <int>[
      for (final int i in vowelIndices)
        if (phones[i].stress == 2) i,
    ];
    final int targetIndex = primary.isNotEmpty
        ? primary.last
        : secondary.isNotEmpty
            ? secondary.last
            : vowelIndices.first;
    final Phone target = phones[targetIndex];

    // Y + UW is the long-u (yod) vowel AOU. The Y is not a separate onset.
    final bool yod = targetIndex > 0 &&
        phones[targetIndex - 1].phoneme == 'Y' &&
        target.phoneme == 'UW';

    final Set<int> ids = <int>{};
    if (yod) {
      ids.addAll(_vowelsAou);
    } else {
      ids.addAll(_vowelKeyIds(target.phoneme, spelling));
    }

    if (mergeEarlier) {
      for (final int i in vowelIndices) {
        if (i >= targetIndex) {
          break;
        }
        final String phoneme = phones[i].phoneme;
        if (phoneme == 'ER') {
          // The r is added to the onset below; do not put it in the vowel set.
          continue;
        }
        ids.addAll(_simpleVowelKeys(phoneme));
      }
    }

    // Final unstressed -y/-ie marker: add E to the vowel group. This is the
    // documented "add E for an ee sound" pattern used by OEPBL (only).
    final int lastVowel = vowelIndices.last;
    if (lastVowel > targetIndex &&
        phones[lastVowel].phoneme == 'IY' &&
        (phones[lastVowel].stress == 0 || phones[lastVowel].stress == null)) {
      ids.add(_e);
    }

    final List<String> onset = <String>[];
    for (int i = 0; i < targetIndex; i++) {
      final Phone phone = phones[i];
      if (phone.isVowel) {
        // An unstressed ER before the nucleus contributes its r to the next
        // syllable's onset (around, direct).
        if (phone.phoneme == 'ER' && phone.stress == 0) {
          onset.add('R');
        }
        continue;
      }
      if (yod && i == targetIndex - 1 && phone.phoneme == 'Y') {
        continue;
      }
      onset.add(phone.phoneme);
    }
    if (applySilentLetters) {
      _applySilentInitials(word, phones, onset);
    }
    for (final String phoneme in onset) {
      ids.addAll(_onsetKeys[phoneme] ?? const <int>[]);
    }

    final List<String> coda = <String>[];
    for (int i = targetIndex + 1; i < phones.length; i++) {
      final Phone phone = phones[i];
      if (phone.isVowel) {
        if (phone.phoneme == 'ER') {
          coda.add('R');
        }
        continue;
      }
      coda.add(phone.phoneme);
    }
    _applySyllabicLe(spelling, coda);
    final List<String> mergedCoda = _mergeCoda(coda);
    for (final String phoneme in mergedCoda) {
      ids.addAll(_codaKeys[phoneme] ?? const <int>[]);
    }

    ids.addAll(extraKeys);

    if (ids.length > stenoKeyCount) {
      return null;
    }
    final Stroke stroke;
    try {
      stroke = Stroke.fromKeyIds(ids);
    } on RangeError {
      return null;
    }
    if (stroke.isEmpty) {
      return null;
    }
    final String outline = stroke.format();
    final Stroke reparsed;
    try {
      reparsed = Stroke.parse(outline);
    } on FormatException {
      return null;
    }
    // Reject the rare canonical form that would be read back as different
    // keys (the engine documents this as its known notation ambiguity).
    if (reparsed.signature != stroke.signature) {
      return null;
    }
    if (stroke.keyIds.length < 1 || stroke.keyIds.length > stenoKeyCount) {
      return null;
    }

    return _Built(
      outline: outline,
      signature: stroke.signature,
      keyIds: stroke.keyIds.toSet(),
      variant: variantOverride ?? (mergeEarlier ? 'merged' : 'base'),
      targetPhone: target.phoneme,
      onsetPhones: List<String>.unmodifiable(onset),
      codaPhones: List<String>.unmodifiable(mergedCoda),
    );
  }

  void _applySilentInitials(
    String word,
    List<Phone> phones,
    List<String> onset,
  ) {
    final String spelling = _spellingOf(word);
    void prepend(String phoneme) {
      if (onset.isEmpty || onset.first != phoneme) {
        onset.insert(0, phoneme);
      }
    }

    if (spelling.startsWith('wr')) {
      prepend('W');
    } else if (spelling.startsWith('kn')) {
      prepend('K');
    } else if (spelling.startsWith('gn')) {
      prepend('G');
    } else if (spelling.startsWith('ps') || spelling.startsWith('pn')) {
      prepend('P');
    }
    // hour, honest: the written h is not in the CMUdict phone list.
    if (spelling.startsWith('h') && phones.isNotEmpty && phones.first.isVowel) {
      prepend('HH');
    }
  }

  void _applySyllabicLe(String spelling, List<String> coda) {
    if (!spelling.endsWith('le')) {
      return;
    }
    // little, battle: -tle is written with L, not T+L.
    if (coda.contains('T') && coda.contains('L')) {
      coda.remove('T');
      return;
    }
    // circle: a stop + syllabic L is written without a second L.
    if ((coda.contains('K') || coda.contains('G')) && coda.contains('L')) {
      coda.remove('L');
    }
  }

  static List<String> _mergeCoda(List<String> coda) {
    final List<String> out = <String>[];
    int i = 0;
    while (i < coda.length) {
      if (i + 1 < coda.length) {
        final String pair = '${coda[i]} ${coda[i + 1]}';
        final String? merged = _codaPairs[pair];
        if (merged != null) {
          out.add(merged);
          i += 2;
          continue;
        }
      }
      out.add(coda[i]);
      i++;
    }
    return out;
  }

  static String _spellingOf(String word) =>
      word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
}

class _Built {
  const _Built({
    required this.outline,
    required this.signature,
    required this.keyIds,
    required this.variant,
    required this.targetPhone,
    required this.onsetPhones,
    required this.codaPhones,
  });

  final String outline;
  final String signature;
  final Set<int> keyIds;
  final String variant;
  final String targetPhone;
  final List<String> onsetPhones;
  final List<String> codaPhones;
}

// Key ids in the engine's steno order:
// S0 T1 K2 P3 W4 H5 R6 A7 O8 *9 E10 U11 F12 R13 P14 B15 L16 G17 T18 S19 D20 Z21
const int _a = 7;
const int _o = 8;
const int _star = 9;
const int _e = 10;
const int _u = 11;

const List<int> _vowelsAou = <int>[_a, _o, _u];

const List<int> rightTagOrder = <int>[20, 21, 17, 19, 18, 15, 16, 14, 13, 12];

const Map<String, List<int>> _onsetKeys = <String, List<int>>{
  'B': <int>[3, 4],
  'CH': <int>[2, 5],
  'D': <int>[1, 2],
  'DH': <int>[1, 5],
  'F': <int>[1, 3],
  'G': <int>[1, 2, 3, 4],
  'HH': <int>[5],
  'JH': <int>[0, 2, 4, 6],
  'K': <int>[2],
  'L': <int>[5, 6],
  'M': <int>[3, 5],
  'N': <int>[1, 3, 5],
  'P': <int>[3],
  'R': <int>[6],
  'S': <int>[0],
  'SH': <int>[0, 5],
  'T': <int>[1],
  'TH': <int>[1, 5],
  'V': <int>[0, 6],
  'W': <int>[4],
  'Y': <int>[2, 4, 6],
  'Z': <int>[0, 9],
  'ZH': <int>[0, 5],
};

const Map<String, List<int>> _codaKeys = <String, List<int>>{
  'B': <int>[15],
  'CH': <int>[12, 14],
  'D': <int>[20],
  'DH': <int>[9, 18],
  'F': <int>[12],
  'G': <int>[17],
  'HH': <int>[],
  'JH': <int>[14, 15, 16, 17],
  'K': <int>[15, 17],
  'L': <int>[16],
  'M': <int>[14, 16],
  'N': <int>[14, 15],
  'NG': <int>[14, 15, 17],
  'PBG': <int>[14, 15, 17],
  'P': <int>[14],
  'R': <int>[13],
  'S': <int>[19],
  'SH': <int>[13, 15],
  'T': <int>[18],
  'TH': <int>[9, 18],
  'V': <int>[9, 12],
  'W': <int>[],
  'Y': <int>[],
  'Z': <int>[21],
  'ZH': <int>[13, 15],
  // Merge tokens.
  '*PBG': <int>[9, 14, 15, 17],
  'FRPBLG': <int>[12, 13, 14, 15, 16, 17],
  'FRP': <int>[12, 13, 14],
  'FRB': <int>[12, 13, 15],
  'FRPB': <int>[12, 13, 14, 15],
  'FT': <int>[12, 18],
  'FPL': <int>[12, 14, 16],
  'BGS': <int>[15, 17, 19],
  'DZ': <int>[20, 21],
  'PL': <int>[14, 16],
};

const Map<String, String> _codaPairs = <String, String>{
  'NG K': '*PBG',
  'N CH': 'FRPBLG',
  'N JH': 'PBG',
  'M P': 'FRP',
  'R F': 'FRB',
  'R V': 'FRB',
  'R CH': 'FRPB',
  'S T': 'FT',
  'S M': 'FPL',
  'K S': 'BGS',
  'D Z': 'DZ',
  'P L': 'PL',
};

List<int> _vowelKeyIds(String phoneme, String spelling) {
  switch (phoneme) {
    case 'AA':
      if (_hasAny(spelling, <String>['aw', 'au', 'al'])) {
        return <int>[_a, _u];
      }
      if (spelling.contains('o')) {
        return <int>[_o];
      }
      return <int>[_a];
    case 'AE':
      return <int>[_a];
    case 'AH':
      return <int>[_u];
    case 'AO':
      if (_hasAny(spelling, <String>['aw', 'au', 'all', 'alk', 'al']) ||
          spelling == 'door' ||
          spelling.startsWith('wa') ||
          spelling.startsWith('wo')) {
        return <int>[_a, _u];
      }
      if (spelling.contains('oo')) {
        return <int>[_a, _o];
      }
      return <int>[_o];
    case 'AW':
      return <int>[_o, _u];
    case 'AY':
      return <int>[_a, _o, _e, _u];
    case 'EH':
      if (spelling.contains('ea') || spelling.contains('air')) {
        return <int>[_a, _e];
      }
      return <int>[_e];
    case 'ER':
      if (_hasAny(spelling, <String>['ir', 'ear'])) {
        return <int>[_e, _u, 13];
      }
      if (spelling.contains('ur')) {
        return <int>[_u, 13];
      }
      if (spelling.contains('or')) {
        return <int>[_o, 13];
      }
      return <int>[_e, 13];
    case 'EY':
      return <int>[_a, _e, _u];
    case 'IH':
      return <int>[_e, _u];
    case 'IY':
      return <int>[_a, _o, _e];
    case 'OW':
      return <int>[_o, _e];
    case 'OY':
      return <int>[_o, _e, _u];
    case 'UH':
      if (spelling.contains('oo') || spelling.contains('o')) {
        return <int>[_a, _o];
      }
      return <int>[_u];
    case 'UW':
      if (spelling.contains('oo')) {
        return <int>[_a, _o];
      }
      return <int>[_a, _o, _u];
    default:
      return <int>[_u];
  }
}

List<int> _simpleVowelKeys(String phoneme) {
  switch (phoneme) {
    case 'AA':
    case 'AE':
      return <int>[_a];
    case 'AH':
      return <int>[_u];
    case 'AO':
      return <int>[_o];
    case 'AW':
      return <int>[_o, _u];
    case 'AY':
      return <int>[_a, _o, _e, _u];
    case 'EH':
      return <int>[_e];
    case 'EY':
      return <int>[_a, _e, _u];
    case 'IH':
      return <int>[_e, _u];
    case 'IY':
      return <int>[_e];
    case 'OW':
      return <int>[_o, _e];
    case 'OY':
      return <int>[_o, _e, _u];
    case 'UH':
    case 'UW':
      return <int>[_a, _o];
    default:
      return <int>[];
  }
}

bool _hasAny(String text, List<String> needles) =>
    needles.any((String needle) => text.contains(needle));

String _letter(int id) => stenoKeys[id].letter;
