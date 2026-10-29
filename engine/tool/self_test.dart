// Self-test for the steno engine.
//
// Run with:  dart run tool/self_test.dart
//
// Uses plain checks (no package:test), so it works in any Dart environment
// without fetching dependencies.

import 'dart:math';

import 'package:steno_engine/steno_engine.dart';

int _checks = 0;

void _check(bool condition, String message) {
  _checks++;
  if (!condition) {
    throw StateError('FAIL: $message');
  }
}

void _equals(Object? actual, Object? expected, String label) {
  _checks++;
  if (actual != expected) {
    throw StateError(
      'FAIL: $label\n  expected: $expected\n  actual:   $actual',
    );
  }
}

void _throws(void Function() body, String label, Type expectedType) {
  _checks++;
  try {
    body();
  } catch (error) {
    final bool matches =
        (expectedType == ArgumentError && error is ArgumentError) ||
            (expectedType == FormatException && error is FormatException) ||
            (expectedType == RangeError && error is RangeError) ||
            (expectedType == StateError && error is StateError) ||
            error.runtimeType == expectedType;
    if (!matches) {
      throw StateError(
        'FAIL: $label threw ${error.runtimeType}, expected $expectedType\n'
        '  error: $error',
      );
    }
    return;
  }
  throw StateError('FAIL: $label did not throw $expectedType');
}

class StrokeCase {
  const StrokeCase(this.input, this.ids, this.canonical, this.description);

  /// Stroke text to parse (may be non-canonical, e.g. `HR-S`).
  final String input;

  /// Expected set of key ids, in steno order.
  final List<int> ids;

  /// Expected canonical formatting.
  final String canonical;

  /// Expected [describeKeys] output.
  final String description;
}

const List<StrokeCase> _cases = <StrokeCase>[
  StrokeCase('KAT', <int>[2, 7, 18], 'KAT', 'left K · vowel A · right T'),
  StrokeCase('PHAT', <int>[3, 5, 7, 18], 'PHAT', 'left PH · vowel A · right T'),
  StrokeCase('OPB', <int>[8, 14, 15], 'OPB', 'vowel O · right PB'),
  StrokeCase('-T', <int>[18], '-T', 'right T'),
  StrokeCase('AEU', <int>[7, 10, 11], 'AEU', 'vowels AEU'),
  StrokeCase('HR-S', <int>[5, 6, 19], 'HRS', 'left HR · right S'),
  StrokeCase('TKPWO', <int>[1, 2, 3, 4, 8], 'TKPWO', 'left TKPW · vowel O'),
  StrokeCase('KHAOEULD', <int>[2, 5, 7, 8, 10, 11, 16, 20], 'KHAOEULD',
      'left KH · vowels AOEU · right LD'),
  StrokeCase('P*EUPBG', <int>[3, 9, 10, 11, 14, 15, 17], 'P*EUPBG',
      'left P · vowels EU · asterisk · right PBG'),
  StrokeCase('*', <int>[9], '*', 'asterisk'),
  StrokeCase('S', <int>[0], 'S', 'left S'),
  StrokeCase('-Z', <int>[21], '-Z', 'right Z'),
  StrokeCase('A*EU', <int>[7, 9, 10, 11], 'A*EU', 'vowels AEU · asterisk'),
  StrokeCase('AT', <int>[7, 18], 'AT', 'vowel A · right T'),
  StrokeCase(
      'STKPWHRAO*EUFRPBLGTSDZ',
      <int>[
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
      ],
      'STKPWHRAO*EUFRPBLGTSDZ',
      'left STKPWHR · vowels AOEU · asterisk · right FRPBLGTSDZ'),
];

void selfTest() {
  _testKeyTable();
  _testParsingAndFormatting();
  _testDescribe();
  _testInvalidStrokes();
  _testRoundTrips();
  _testSignatures();
  _testDictionary();
  _testDictionaryErrors();
  _testSha256();
}

void _testKeyTable() {
  _equals(stenoKeys.length, 22, '22 keys in steno order');
  _equals(
    stenoKeys.map((StenoKey key) => key.letter).join(),
    'STKPWHRAO*EUFRPBLGTSDZ',
    'steno order letters',
  );
  _equals(
    stenoKeys.map((StenoKey key) => key.id).join(','),
    List<int>.generate(22, (int i) => i).join(','),
    'key ids match steno order positions',
  );
  _equals(keysOnSide(KeySide.left).length, 7, '7 left-hand keys');
  _equals(keysOnSide(KeySide.vowel).length, 4, '4 vowel keys');
  _equals(keysOnSide(KeySide.star).length, 1, '1 asterisk key');
  _equals(keysOnSide(KeySide.right).length, 10, '10 right-hand keys');
  _equals(firstRightHandIndex, 12, 'right-hand block starts at index 12');
  _check(keyAt(12).isRightHand, '-F is the first right-hand key');
  _equals(keyAt(11).letter, 'U', 'key 11 is U');
  _equals(keyAt(11).side, KeySide.vowel, 'key 11 is a vowel');
  _equals(keyAt(0).label, 'S-', 'left key label');
  _equals(keyAt(9).label, '*', 'star label');
  _equals(keyAt(18).label, '-T', 'right key label');
  _equals(keysForLetter('T').map((StenoKey key) => key.id).join(','), '1,18',
      'letters appear once per side');

  // Every single key formats to its letter (with a leading dash on the right)
  // and parses back to exactly that key.
  for (final StenoKey key in stenoKeys) {
    final String text = key.isRightHand ? '-${key.letter}' : key.letter;
    final Stroke stroke = Stroke.parse(text);
    _equals(stroke.keyIds.join(','), '${key.id}', 'single-key parse $text');
    _equals(stroke.format(), text, 'single-key format $text');
  }
}

void _testParsingAndFormatting() {
  for (final StrokeCase testCase in _cases) {
    final Stroke stroke = Stroke.parse(testCase.input);
    _equals(
      stroke.keyIds.join(','),
      testCase.ids.join(','),
      'parse ${testCase.input} key ids',
    );
    _equals(stroke.format(), testCase.canonical, 'format ${testCase.input}');
    _equals(
        stroke.toString(), testCase.canonical, 'toString ${testCase.input}');
    _equals(
      stroke.signature,
      testCase.ids.join('|'),
      'signature ${testCase.input}',
    );
    _equals(
        stroke.describe(), testCase.description, 'describe ${testCase.input}');
    _equals(describeStroke(testCase.input), testCase.description,
        'describeStroke ${testCase.input}');

    // Canonical text round-trips.
    final Stroke reparsed = Stroke.parse(testCase.canonical);
    _equals(reparsed.signature, stroke.signature,
        'canonical round-trip ${testCase.canonical}');
    _equals(reparsed.format(), testCase.canonical,
        'canonical is stable ${testCase.canonical}');
    _check(reparsed == stroke, 'equality after round-trip ${testCase.input}');
    _equals(reparsed.hashCode, stroke.hashCode,
        'hashCode after round-trip ${testCase.input}');

    // The first selected key being right-hand is the only reason for a dash.
    final bool startsOnRight = keyAt(testCase.ids.first).isRightHand;
    _equals(
      testCase.canonical.startsWith('-'),
      startsOnRight,
      'leading dash iff first key is right-hand: ${testCase.canonical}',
    );
    if (!startsOnRight) {
      _check(!testCase.canonical.contains('-'),
          'no interior dashes in ${testCase.canonical}');
    }
  }

  // A dash jumps to the right-hand block; after a vowel, T resolves to -T.
  _equals(Stroke.parse('AT').signature, Stroke.parse('A-T').signature,
      'A-T canonicalises to AT');
  _equals(Stroke.parse('A-T').format(), 'AT', 'A-T formats without a dash');
  _equals(Stroke.parse('T').signature, '1', 'bare T is the left T');
  _equals(Stroke.parse('-T').signature, '18', 'dash selects the right T');
  _equals(Stroke.parse('TS').signature, '1|19', 'TS spans both hands');
  _equals(Stroke.parse('T-S').format(), 'TS', 'T-S canonicalises to TS');

  // Parsing is case-insensitive and tolerates surrounding whitespace.
  _equals(Stroke.parse('kat').format(), 'KAT', 'lowercase input');
  _equals(
      Stroke.parse('  TKPWO  ').format(), 'TKPWO', 'surrounding whitespace');
  _equals(Stroke.parse('p*eupbg').format(), 'P*EUPBG', 'lowercase star input');

  // Non-canonical input is accepted and canonicalised.
  _equals(Stroke.parse('HR-S').format(), 'HRS', 'HR-S canonicalises to HRS');
  _equals(Stroke.parse('S-T').format(), 'ST', 'S-T canonicalises to ST');

  // Building from ids is order-independent and de-duplicates.
  _equals(Stroke.fromKeyIds(<int>[18, 2, 7]).format(), 'KAT', 'unordered ids');
  _equals(Stroke.fromKeyIds(<int>[18, 2, 7, 2, 18]).signature, '2|7|18',
      'duplicate ids collapse');
  _equals(Stroke.fromKeyIds(const <int>[]).format(), '',
      'empty stroke formats as empty');
  _equals(Stroke.fromKeyIds(const <int>[]).describe(), 'empty',
      'empty stroke describes as empty');
  _throws(
      () => Stroke.fromKeyIds(<int>[22]), 'id 22 is out of range', RangeError);
  _throws(
      () => Stroke.fromKeyIds(<int>[-1]), 'id -1 is out of range', RangeError);

  // tryParse.
  _equals(Stroke.tryParse('KAT')?.format(), 'KAT', 'tryParse valid');
  _equals(Stroke.tryParse('AK'), null, 'tryParse invalid');
  _equals(Stroke.tryParse(''), null, 'tryParse empty');
}

void _testDescribe() {
  _equals(describeKeys(<int>[2, 7, 18]), 'left K · vowel A · right T',
      'describe KAT');
  _equals(describeKeys(<int>[7, 10, 11]), 'vowels AEU', 'plural vowels');
  _equals(describeKeys(<int>[7]), 'vowel A', 'single vowel');
  _equals(describeKeys(<int>[9]), 'asterisk', 'asterisk');
  _equals(
      describeKeys(<int>[9, 2]), 'left K · asterisk', 'star after left group');
  _equals(describeKeys(<int>[18]), 'right T', 'right only');
  _equals(describeKeys(<int>[21, 12, 0]), 'left S · right FZ',
      'groups are ordered, not input ordered');
  _equals(describeKeys(<int>[]), 'empty', 'empty description');
  _equals(
      describeKeys(<int>[
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
      ]),
      'left STKPWHR · vowels AOEU · asterisk · right FRPBLGTSDZ',
      'full keyboard description');
}

void _testInvalidStrokes() {
  const List<String> invalid = <String>[
    '',
    '   ',
    '-',
    'A-',
    'S-T-',
    '--T',
    'AK', // K only exists on the left, before A
    'UO', // O only exists before U
    'T-E', // no E key remains on the right
    '*A', // A is before *
    'OA', // A is before O
    'TTT', // only two T keys exist
    '#', // digits are not part of this model
    'S T', // spaces are not part of a stroke
    '1', // digits are not part of this model
    'Ö', // not a steno key
  ];
  for (final String stroke in invalid) {
    _throws(() => Stroke.parse(stroke), 'invalid stroke "$stroke"',
        FormatException);
  }

  try {
    Stroke.parse('AK');
    throw StateError('FAIL: AK should not parse');
  } on FormatException catch (error) {
    _check('${error.message}'.contains('AK'), 'error names the stroke');
    _check('${error.message}'.contains('K'), 'error names the offending key');
  }

  try {
    Stroke.parse('-');
    throw StateError('FAIL: "-" should not parse');
  } on FormatException catch (error) {
    final String message = '${error.message}'.toLowerCase();
    _check(
      message.contains('dash') || message.contains('empty'),
      'dash-only error mentions the dash or emptiness',
    );
  }
}

void _testRoundTrips() {
  // A canonical string cannot always carry every chord: with dashes allowed
  // only at the start, {S-, -R} is written "SR", which the parser reads back
  // as {S-, R-}. [faithful] detects the (rare) chords where writing the
  // letters alone would be re-read as a different chord.
  bool faithful(Stroke stroke) {
    final List<int> ids = stroke.keyIds;
    for (var i = 1; i < ids.length; i++) {
      final int id = ids[i];
      if (!keyAt(id).isRightHand) {
        continue;
      }
      final Iterable<StenoKey> twins = keysForLetter(keyAt(id).letter);
      if (twins.isEmpty || twins.first.id >= id) {
        continue;
      }
      if (ids[i - 1] < twins.first.id) {
        return false;
      }
    }
    return true;
  }

  var faithfulPairs = 0;
  var lossyPairs = 0;

  // Every pair of keys must either round-trip exactly, or be a documented
  // lossy chord whose canonical string is still stable.
  for (var a = 0; a < stenoKeyCount; a++) {
    for (var b = a + 1; b < stenoKeyCount; b++) {
      final Stroke stroke = Stroke.fromKeyIds(<int>[b, a]);
      final String text = stroke.format();
      final Stroke parsed = Stroke.parse(text);
      _equals(parsed.format(), text, 'pair formatting stable $text');
      if (faithful(stroke)) {
        faithfulPairs++;
        _equals(parsed.signature, stroke.signature, 'pair round-trip $text');
      } else {
        lossyPairs++;
        _check(parsed.signature != stroke.signature,
            'known lossy pair $text is detected');
      }
      _check(!stroke.describe().contains('empty'), 'pair is described $text');
    }
  }
  _equals(faithfulPairs + lossyPairs, 231, 'all key pairs covered');
  _equals(lossyPairs, 10, 'only same-letter crossing pairs are lossy');

  // Deterministic pseudo-random larger chords.
  final Random random = Random(20261028);
  for (var trial = 0; trial < 2000; trial++) {
    final Set<int> ids = <int>{
      for (var id = 0; id < stenoKeyCount; id++)
        if (random.nextBool()) id,
    };
    final Stroke stroke = Stroke.fromKeyIds(ids);
    final String text = stroke.format();
    final Stroke parsed = Stroke.parse(text);
    _equals(parsed.format(), text, 'random formatting stable "$text"');
    _check(
        parsed.describe() != 'empty', 'random description populated "$text"');
    if (faithful(stroke)) {
      _equals(parsed.signature, stroke.signature, 'random round-trip "$text"');
    }
  }

  // The model's known ambiguity, made explicit: the set {S-, -R} formats as
  // "SR" because only a leading dash is allowed, and "SR" parses as {S-, R-}.
  // Signatures keep the two chords distinct.
  final Stroke sLeftRRight = Stroke.fromKeyIds(<int>[0, 13]);
  _equals(sLeftRRight.format(), 'SR', 'S + -R formats without interior dash');
  _equals(sLeftRRight.signature, '0|13', 'S + -R keeps its own signature');
  _equals(Stroke.parse('S-R').signature, '0|13', 'S-R parses as S + -R');
  _equals(Stroke.parse('SR').signature, '0|6', 'SR parses as S + R-');
  _check(Stroke.parse('S-R') != Stroke.parse('SR'),
      'the two chords remain distinct values');

  // Long chords that mix hands and vowels.
  for (final String stroke in <String>[
    'STKPWHR',
    'AOEU',
    'FRPBLGTSDZ',
    'STKPWHRAO*EUFRPBLGTSDZ',
    'KAT',
    'PHAOEUFRPBLG',
  ]) {
    final Stroke parsed = Stroke.parse(stroke);
    _equals(Stroke.parse(parsed.format()).signature, parsed.signature,
        'long round-trip $stroke');
  }
}

void _testSignatures() {
  final Stroke kat = Stroke.parse('KAT');
  _equals(kat.signature, '2|7|18', 'KAT signature');
  _equals(kat.signature, Stroke.fromKeyIds(<int>[18, 7, 2]).signature,
      'signature ignores insertion order');
  _check(kat == Stroke.parse('kat'), 'equality ignores notation');
  _check(kat != Stroke.parse('TKAT'), 'different chords are unequal');
  _equals(kat.keyIds.join(','), '2,7,18', 'key ids are sorted');
  _check(kat.containsKeyId(7), 'containsKeyId');
  _check(kat.containsKey(keyAt(18)), 'containsKey');
  _check(!kat.containsKeyId(19), 'absent key');
  _check(kat.sameKeysAs(Stroke.parse('KAT')), 'sameKeysAs');

  final Stroke rightOnly = Stroke.parse('-FR');
  _equals(rightOnly.signature, '12|13', 'right-only signature');
  _equals(rightOnly.format(), '-FR', 'right-only formatting');
}

void _testDictionary() {
  final StenoDictionary dictionary = StenoDictionary(<String, String>{
    'cat': 'KAT',
    'at': 'AT',
    'bat': 'PWAT',
    'the': '-T',
    'out': 'OUT',
  });

  _equals(dictionary.length, 5, 'dictionary length');
  _check(!dictionary.isEmpty, 'dictionary is not empty');
  _equals(dictionary.allWords.join(','), 'at,bat,cat,out,the',
      'allWords is sorted');

  _equals(dictionary.strokeForWord('cat'), 'KAT', 'strokeForWord');
  _equals(dictionary.strokeForWord('the'), '-T', 'strokeForWord right-hand');
  _equals(dictionary.strokeForWord('dog'), null, 'strokeForWord unknown');
  _equals(dictionary.strokeObjectForWord('cat')?.signature, '2|7|18',
      'strokeObjectForWord');
  _equals(dictionary.signatureForWord('cat'), '2|7|18', 'signatureForWord');

  _equals(dictionary.wordForStroke('KAT'), 'cat', 'wordForStroke');
  _equals(dictionary.wordForStroke('kat'), 'cat',
      'wordForStroke is case-insensitive');
  _equals(dictionary.wordForStroke(' KAT '), 'cat',
      'wordForStroke trims whitespace');
  _equals(dictionary.wordForStroke('-T'), 'the', 'wordForStroke right-hand');
  _equals(dictionary.wordForStroke('ZZZ'), null, 'wordForStroke invalid');
  _equals(dictionary.wordForStroke('KHAOEULD'), null,
      'wordForStroke is not a prefix search');
  _equals(dictionary.wordForStroke(''), null, 'wordForStroke empty');

  _equals(dictionary.wordForSignature('2|7|18'), 'cat', 'wordForSignature');
  _equals(dictionary.wordForSignature(' 2|7|18 '), 'cat',
      'wordForSignature ignores padding');
  _equals(dictionary.wordForSignature('1|2'), null, 'wordForSignature unknown');
  _equals(dictionary.wordForSignature(''), null, 'wordForSignature empty');

  _check(dictionary.containsWord('cat'), 'containsWord');
  _check(!dictionary.containsWord('Cat'), 'containsWord is case-sensitive');

  _equals(dictionary.describeWord('cat'),
      'cat: KAT (left K · vowel A · right T)', 'describeWord');
  _equals(dictionary.describeWord('the'), 'the: -T (right T)',
      'describeWord right-hand');
  _equals(dictionary.describeWord('dog'), null, 'describeWord unknown');

  _equals(dictionary.entries['cat'], 'KAT', 'entries');

  final StenoDictionary empty = StenoDictionary.empty();
  _check(empty.isEmpty, 'empty dictionary');
  _equals(empty.length, 0, 'empty dictionary length');
  _equals(empty.allWords.join(','), '', 'empty dictionary words');
  _equals(empty.strokeForWord('cat'), null, 'empty dictionary lookup');
  _equals(StenoDictionary(<String, String>{}).allWords.join(','), '',
      'empty map dictionary');

  // A word may use a non-canonical stroke; it is stored canonically.
  final StenoDictionary mixed = StenoDictionary(<String, String>{
    'her': 'HR-S',
  });
  _equals(mixed.strokeForWord('her'), 'HRS',
      'non-canonical entry stored canonically');
  _equals(mixed.wordForStroke('HRS'), 'her', 'canonical lookup');
  _equals(mixed.wordForStroke('HR-S'), 'her', 'non-canonical lookup');
}

void _testDictionaryErrors() {
  // Same chord, same notation, different words.
  _throws(
    () => StenoDictionary(<String, String>{'cat': 'KAT', 'kit': 'KAT'}),
    'duplicate signature is rejected',
    ArgumentError,
  );
  // Same chord, different notation, different words.
  _throws(
    () => StenoDictionary(<String, String>{'her': 'HR-S', 'fur': 'HRS'}),
    'duplicate signature across notations is rejected',
    ArgumentError,
  );
  // Same chord, redundant dash, different words.
  _throws(
    () => StenoDictionary(<String, String>{'one': 'TS', 'two': 'T-S'}),
    'duplicate signature across dash placement is rejected',
    ArgumentError,
  );

  try {
    StenoDictionary(<String, String>{'her': 'HR-S', 'fur': 'HRS'});
    throw StateError('FAIL: collision should throw');
  } on ArgumentError catch (error) {
    final String message = '${error.message}';
    _check(message.contains('her'), 'collision names the first word');
    _check(message.contains('fur'), 'collision names the second word');
    _check(message.contains('HRS'), 'collision names the canonical stroke');
    _check(message.contains('5|6|19'), 'collision names the signature');
  }

  // Invalid strokes are rejected at construction time, with word context.
  _throws(
    () => StenoDictionary(<String, String>{'x': 'AK'}),
    'invalid stroke is rejected',
    FormatException,
  );
  try {
    StenoDictionary(<String, String>{'x': 'AK'});
    throw StateError('FAIL: invalid stroke should throw');
  } on FormatException catch (error) {
    _check('${error.message}'.contains('x'),
        'invalid stroke error names the word');
    _check('${error.message}'.contains('AK'),
        'invalid stroke error names the stroke');
  }

  _throws(
    () => StenoDictionary(<String, String>{'': 'KAT'}),
    'empty word is rejected',
    ArgumentError,
  );
  _throws(
    () => StenoDictionary(<String, String>{'   ': 'KAT'}),
    'blank word is rejected',
    ArgumentError,
  );

  // Distinct chords are fine.
  final StenoDictionary ok = StenoDictionary(<String, String>{
    'cat': 'KAT',
    'kit': 'KEUT',
    'cut': 'KUT',
  });
  _equals(ok.length, 3, 'distinct chords accepted');
}

void _testSha256() {
  // FIPS 180-4 / NIST example vectors.
  _equals(
    sha256Hex(<int>[]),
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    'SHA-256 empty input',
  );
  _equals(
    sha256Hex('abc'.codeUnits),
    'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    'SHA-256 abc',
  );
  _equals(
    sha256Hex(
      'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'.codeUnits,
    ),
    '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
    'SHA-256 two-block vector',
  );
  _equals(
    sha256Hex(
      'The quick brown fox jumps over the lazy dog'.codeUnits,
    ),
    'd7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592',
    'SHA-256 pangram',
  );
}

void main() {
  selfTest();
  print('Ran $_checks checks.');
  print('ALL ENGINE TESTS PASSED');
}
