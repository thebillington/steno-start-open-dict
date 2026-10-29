import 'dart:convert';
import 'dart:io';

import 'package:steno_engine/steno_engine.dart';
import 'package:steno_start_generator/steno_start_generator.dart';
import 'package:test/test.dart';

Directory _findRoot() {
  final Directory cwd = Directory.current;
  if (File('${cwd.path}/data/source_words.txt').existsSync()) {
    return cwd;
  }
  if (File('${cwd.parent.path}/data/source_words.txt').existsSync()) {
    return cwd.parent;
  }
  throw StateError('Run the tests from the repository or generator directory.');
}

void main() {
  late Directory root;
  late BuildResult result;

  setUpAll(() {
    root = _findRoot();
    result = Generator(root: root).build(write: false);
  });

  test('the build passes every self-check', () {
    expect(result.checks, isNotEmpty);
    for (final CheckResult check in result.checks) {
      expect(check.passed, isTrue, reason: '${check.name}: ${check.detail}');
    }
  });

  test('dictionary covers exactly the 500 source words', () {
    final List<String> words = File('${root.path}/data/source_words.txt')
        .readAsLinesSync()
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList();
    expect(words.length, 500);
    expect(result.dictionary.length, 500);
    expect(result.dictionary.keys.toSet(), words.toSet());
    expect(result.entries.length, 500);
  });

  test('all entries use a single, unique stroke', () {
    final Set<String> signatures = <String>{};
    for (final DictionaryEntry entry in result.entries) {
      final Stroke stroke = Stroke.parse(entry.outline);
      expect(stroke.format(), entry.outline);
      expect(Stroke.parse(stroke.format()).signature, stroke.signature);
      expect(stroke.keyIds.length, inInclusiveRange(1, 22));
      expect(stroke.keyIds.toSet().length, stroke.keyIds.length);
      expect(
        signatures.add(stroke.signature),
        isTrue,
        reason: 'duplicate signature for ${entry.word}',
      );
    }
    expect(signatures.length, 500);
  });

  test('briefs are canonical and notation-faithful', () {
    final Map<String, Brief> briefs = allBriefs();
    expect(briefs, isNotEmpty);
    for (final MapEntry<String, Brief> entry in briefs.entries) {
      final Stroke stroke = Stroke.parse(entry.value.outline);
      expect(
        stroke.format(),
        entry.value.outline,
        reason: 'brief ${entry.key}',
      );
      expect(
        Stroke.parse(stroke.format()).signature,
        stroke.signature,
        reason: 'brief ${entry.key}',
      );
      expect(entry.value.sourceIds, isNotEmpty);
    }
  });

  test('representative rule and brief forms are stable', () {
    const Map<String, String> expected = <String, String>{
      // Plain phonetic rules.
      'cat': 'KAT',
      'dog': 'TKOG',
      'bird': 'PWEURD',
      'fish': 'TPEURB',
      'cow': 'KOU',
      'tree': 'TRAOE',
      'home': 'HOEPL',
      'school': 'SKAOL',
      'water': 'WAURT',
      'friend': 'TPREPBD',
      'family': 'TPAEPL',
      'little': 'HREUL',
      'circle': 'SEURBG',
      'write': 'WRAOEUT',
      'hour': 'HOUR',
      'many': 'PHAEPB',
      'hurt': 'HURT',
      'church': 'KHUFRP',
      'across': 'KROS',
      'long': 'HROPBG',
      'along': 'HRAUPBG',
      'corn': 'KORPB',
      'orange': 'ORPBG',
      'road': 'RAOD',
      'own': 'OEPB',
      'sit': 'SEUT',
      'here': 'HAOER',
      'every': 'EFR',
      'from': 'TPR',
      // Briefs and documented disambiguations.
      'the': '-T',
      'and': 'SKP',
      'for': 'TPOR',
      'four': 'TPAOR',
      'today': 'TOED',
      'yes': 'KWRES',
      'very': 'SRER',
      'was': 'WAZ',
      'has': 'HAZ',
      'five': 'TPAO*EUF',
      'use': 'AOUZ',
      'door': 'TKAUR',
      'open': 'OEP',
      'city': 'STEUS',
      'hear': 'HAO*ER',
      'ever': '*EFR',
      'picture': 'P*EUFP',
      'always': 'AULS',
      'remember': 'RER',
      'around': 'ARPBD',
      'paper': 'PAEUP',
      'air': 'AEUR',
      'are': 'R',
      'meat': 'PHAO*ET',
      'meet': 'PHAOET',
      'corner': 'KO*RPB',
      'certain': 'S*ERPBT',
      'cross': 'KRO*S',
    };
    for (final MapEntry<String, String> entry in expected.entries) {
      expect(
        result.dictionary[entry.key],
        entry.value,
        reason: 'outline for ${entry.key}',
      );
    }
  });

  test('every entry has registered source ids', () {
    final Object? registryJson = jsonDecode(
      File('${root.path}/sources/sources.json').readAsStringSync(),
    );
    final Map<String, dynamic> registry = registryJson as Map<String, dynamic>;
    final Set<String> ids = <String>{
      for (final dynamic item in registry['sources'] as List<dynamic>)
        (item as Map<String, dynamic>)['id'] as String,
    };
    expect(ids, contains(SourceIds.artOfChording));
    expect(ids, contains(SourceIds.rules));
    var aocEntries = 0;
    for (final DictionaryEntry entry in result.entries) {
      expect(entry.sourceIds, isNotEmpty);
      for (final String id in entry.sourceIds) {
        expect(ids, contains(id));
      }
      if (entry.sourceIds.contains(SourceIds.artOfChording)) {
        aocEntries++;
      }
      expect(entry.changed, entry.signature != entry.plainSignature);
    }
    expect(aocEntries, greaterThanOrEqualTo(20));
  });

  test('Art of Chording examples and briefs are applied exactly', () {
    expect(result.dictionary['always'], 'AULS');
    expect(result.dictionary['every'], 'EFR');
    expect(result.dictionary['remember'], 'RER');
    expect(result.dictionary['around'], 'ARPBD');
    expect(result.dictionary['paper'], 'PAEUP');
    expect(result.dictionary['air'], 'AEUR');
    expect(result.dictionary['are'], 'R');
    expect(result.dictionary['outside'], isNotNull);
    expect(result.multiStroke['outside'], 'OUT/SEUD');
    for (final MapEntry<String, String> example
        in artOfChordingExamples.entries) {
      expect(
        result.dictionary[example.key],
        example.value,
        reason: 'AoC example for ${example.key}',
      );
    }
  });

  test('archived Art of Chording text contains the cited exact forms', () {
    final Directory archive = Directory(
      '${root.path}/sources/art-of-chording/web-archive',
    );
    String page(String name) =>
        File('${archive.path}/$name').readAsStringSync();

    final String how = page('introduction_how-steno-works.txt');
    expect(how, contains('AULS'));
    expect(how, contains('RER'));
    expect(how, contains('EFR'));
    expect(how, contains('KAT'));

    final String bottom = page('layout_bottom-row.html.txt');
    expect(bottom, contains('AEU'));
    expect(bottom, contains('SKP'));
    expect(bottom, contains('R- or -R are'));

    final String ayOy = page('sounds_ay_oy.html.txt');
    expect(ayOy, contains('PAEUP'));
    expect(ayOy, contains('AEUR'));
    expect(ayOy, contains('OEUL'));

    final String prefixes = page('multistroke_prefixes-and-suffixes.html.txt');
    expect(prefixes, contains('ARPBD'));
    expect(prefixes, contains('OUT/SEUD'));
  });

  test('provenance/entries.json is an array with one record per word', () {
    final Object? decoded = jsonDecode(result.entriesJson);
    expect(decoded, isA<List<dynamic>>());
    final List<dynamic> records = decoded as List<dynamic>;
    expect(records.length, 500);
    final Set<String> words = <String>{};
    for (final dynamic item in records) {
      final Map<String, dynamic> record = item as Map<String, dynamic>;
      expect(record['word'], isA<String>());
      expect(record['outline'], isA<String>());
      expect(record['sourceIds'], isA<List<dynamic>>());
      expect((record['sourceIds'] as List<dynamic>), isNotEmpty);
      expect(record['rule'], isA<String>());
      expect(record['changed'], isA<bool>());
      words.add(record['word'] as String);
    }
    expect(words.length, 500);
  });

  test('multi-stroke parts are valid and words are covered', () {
    for (final MapEntry<String, String> entry in result.multiStroke.entries) {
      expect(result.dictionary, contains(entry.key));
      final List<String> parts = entry.value.split('/');
      expect(parts.length, greaterThanOrEqualTo(2));
      for (final String part in parts) {
        final Stroke stroke = Stroke.parse(part);
        expect(stroke.keyIds.length, inInclusiveRange(1, 22));
        expect(Stroke.parse(stroke.format()).signature, stroke.signature);
      }
    }
  });

  test('manifest and build metadata include hashes and the exact command', () {
    final Map<String, dynamic> manifest =
        jsonDecode(result.manifestJson) as Map<String, dynamic>;
    final Map<String, dynamic> build =
        jsonDecode(result.buildJson) as Map<String, dynamic>;
    expect(manifest['license'], 'CC-BY-SA-4.0');
    expect(manifest['command'], buildCommand);
    expect(build['command'], buildCommand);
    expect(build['inputs'], isA<List<dynamic>>());
    expect((build['inputs'] as List<dynamic>), isNotEmpty);
    expect(build['outputs'], isA<Map<String, dynamic>>());
    expect(
      (build['outputs'] as Map<String, dynamic>).keys,
      contains('data/dictionary.json'),
    );
    expect(
      (build['outputs'] as Map<String, dynamic>).keys,
      contains('data/manifest.json'),
    );
    expect(
      (build['outputs'] as Map<String, dynamic>).keys,
      contains('validation/self_check.md'),
    );
    expect((manifest['counts'] as Map<String, dynamic>)['words'], 500);
  });

  test('self-check markdown records every check', () {
    expect(result.selfCheck, contains('# Self-check'));
    for (final CheckResult check in result.checks) {
      expect(result.selfCheck, contains(check.name));
    }
    expect(result.selfCheck, contains('PASS'));
  });

  test('the generator is deterministic', () {
    final BuildResult second = Generator(root: root).build(write: false);
    expect(second.dictionaryJson, result.dictionaryJson);
    expect(second.multiStrokeJson, result.multiStrokeJson);
    expect(second.entriesJson, result.entriesJson);
    expect(second.selfCheck, result.selfCheck);
    expect(second.manifestJson, result.manifestJson);
  });
}
