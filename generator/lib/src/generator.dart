import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:steno_engine/steno_engine.dart';

import 'briefs.dart';
import 'cmudict.dart';
import 'rules.dart';

const String generatorName = 'steno-start-open-dict-generator';
const String generatorVersion = '1.0.0';

/// The exact command used for this clean-lab build. LAB_SPEC.md shows the
/// equivalent command with the lab directory substituted.
const String buildCommand = 'docker run --rm -v '
    '/home/dev/Development/steno-start-open-dict-lab-clean:/workspace '
    '-w /workspace/generator revision-app-dev:latest '
    "sh -lc 'dart pub get && dart run bin/generate.dart && dart test'";

/// Raised when the build cannot produce a complete, sourced dictionary.
class BuildException implements Exception {
  BuildException(this.message, [this.details = const <String>[]]);

  final String message;
  final List<String> details;

  @override
  String toString() => details.isEmpty
      ? 'BuildException: $message'
      : 'BuildException: $message\n${details.join('\n')}';
}

/// A record from `sources/sources.json`.
class SourceRecord {
  const SourceRecord({
    required this.id,
    required this.name,
    required this.url,
    required this.license,
    required this.file,
    required this.files,
    required this.sha256,
    required this.bytes,
    required this.usedFor,
    required this.modified,
    required this.retrieved,
    required this.excluded,
    required this.notes,
  });

  final String id;
  final String name;
  final String url;
  final String license;
  final String file;

  /// Additional source files covered by this registry entry, for sources
  /// archived as a directory (currently the Art of Chording pages).
  final List<String> files;
  final String sha256;
  final int bytes;
  final String usedFor;
  final bool modified;
  final String retrieved;
  final bool excluded;
  final String notes;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'url': url,
        'license': license,
        'file': file,
        if (files.isNotEmpty) 'files': files,
        'sha256': sha256,
        'bytes': bytes,
        'usedFor': usedFor,
        'modified': modified,
        'retrieved': retrieved,
        if (excluded) 'excluded': true,
        if (notes.isNotEmpty) 'notes': notes,
      };
}

/// A word and its final outline.
class DictionaryEntry {
  const DictionaryEntry({
    required this.word,
    required this.outline,
    required this.signature,
    required this.sourceIds,
    required this.description,
    required this.changed,
    required this.brief,
    required this.collisionResolved,
    required this.variant,
    required this.phones,
    required this.multiStroke,
    required this.plainRule,
    required this.plainSignature,
  });

  final String word;
  final String outline;
  final String signature;
  final List<String> sourceIds;
  final String description;
  final bool changed;
  final bool brief;
  final bool collisionResolved;
  final String variant;
  final String phones;
  final List<String> multiStroke;

  /// The plain rule form before any brief, merged vowel or collision tag.
  final String plainRule;
  final String plainSignature;

  Map<String, Object?> toProvenanceJson() => <String, Object?>{
        'word': word,
        'outline': outline,
        'signature': signature,
        'sourceIds': sourceIds,
        'rule': description,
        'changed': changed,
        'brief': brief,
        'collisionResolved': collisionResolved,
        'variant': variant,
        'cmudict': phones,
        'plainRule': plainRule,
        'plainSignature': plainSignature,
        if (multiStroke.isNotEmpty) 'multiStroke': multiStroke,
        'license': 'CC-BY-SA-4.0',
      };
}

class BuildResult {
  BuildResult({
    required this.entries,
    required this.dictionary,
    required this.multiStroke,
    required this.dictionaryJson,
    required this.multiStrokeJson,
    required this.entriesJson,
    required this.manifestJson,
    required this.buildJson,
    required this.selfCheck,
    required this.checks,
    required this.summary,
  });

  final List<DictionaryEntry> entries;
  final Map<String, String> dictionary;
  final Map<String, String> multiStroke;
  final String dictionaryJson;
  final String multiStrokeJson;
  final String entriesJson;
  final String manifestJson;
  final String buildJson;
  final String selfCheck;
  final List<CheckResult> checks;
  final String summary;
}

class CheckResult {
  const CheckResult(this.name, this.passed, this.detail);

  final String name;
  final bool passed;
  final String detail;

  String get mark => passed ? 'PASS' : 'FAIL';
}

/// The deterministic builder.
class Generator {
  Generator({required this.root});

  final Directory root;

  late final Map<String, SourceRecord> _registry = _loadRegistry();

  String _path(String relative) => '${root.path}${Platform.pathSeparator}'
      '${relative.replaceAll('/', Platform.pathSeparator)}';

  String _relative(File file) {
    final String rootPath = root.absolute.path;
    final String full = file.absolute.path;
    if (full.startsWith(rootPath)) {
      return full
          .substring(rootPath.length + 1)
          .replaceAll(Platform.pathSeparator, '/');
    }
    return full;
  }

  Map<String, SourceRecord> _loadRegistry() {
    final File file = File(_path('sources/sources.json'));
    if (!file.existsSync()) {
      throw BuildException('Missing source registry', <String>[file.path]);
    }
    final Object? decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      throw BuildException('sources/sources.json is not a JSON object');
    }
    final List<dynamic> raw =
        decoded['sources'] as List<dynamic>? ?? <dynamic>[];
    final Map<String, SourceRecord> records = <String, SourceRecord>{};
    for (final dynamic item in raw) {
      final Map<String, dynamic> json = item as Map<String, dynamic>;
      final SourceRecord record = SourceRecord(
        id: json['id'] as String,
        name: json['name'] as String,
        url: json['url'] as String,
        license: json['license'] as String,
        file: json['file'] as String,
        files: (json['files'] as List<dynamic>?)
                ?.map((dynamic value) => value as String)
                .toList(growable: false) ??
            const <String>[],
        sha256: json['sha256'] as String,
        bytes: json['bytes'] as int,
        usedFor: (json['usedFor'] as String?) ?? '',
        modified: (json['modified'] as bool?) ?? false,
        retrieved: (json['retrieved'] as String?) ?? '',
        excluded: (json['excluded'] as bool?) ?? false,
        notes: (json['notes'] as String?) ?? '',
      );
      records[record.id] = record;
    }
    return records;
  }

  List<SourceRecord> get _allowedSources =>
      _registry.values.where((SourceRecord s) => !s.excluded).toList()
        ..sort((SourceRecord a, SourceRecord b) => a.id.compareTo(b.id));

  /// Builds all outputs. When [write] is false, only returns the strings.
  BuildResult build({bool write = true}) {
    _validateSources();
    final List<String> words = _readWords();
    if (words.length != 500) {
      throw BuildException(
        'The source word list must contain exactly 500 words.',
        <String>['found ${words.length}'],
      );
    }
    final CmuDict cmu = CmuDict.load(_path('sources/cmudict/cmudict.dict'));
    final RuleEngine rules = RuleEngine(cmu);
    final Map<String, Brief> briefs = allBriefs();

    final Map<String, _Assignment> assignments = <String, _Assignment>{};
    final Map<String, String> signatureOwner = <String, String>{};

    // 1. Briefs are reserved first so their documented forms are stable.
    for (final String word in words) {
      final Brief? brief = briefs[word.toLowerCase()];
      if (brief == null) {
        continue;
      }
      final Stroke stroke;
      try {
        stroke = Stroke.parse(brief.outline);
      } on FormatException catch (error) {
        throw BuildException(
          'Brief for "$word" is not a parseable stroke: ${error.message}',
        );
      }
      final Stroke reparsed = Stroke.parse(stroke.format());
      if (reparsed.signature != stroke.signature) {
        throw BuildException(
          'Brief for "$word" is not notation-faithful: '
          '${brief.outline} -> ${stroke.format()}',
        );
      }
      if (stroke.keyIds.isEmpty || stroke.keyIds.length > stenoKeyCount) {
        throw BuildException('Brief for "$word" must have 1-22 keys.', <String>[
          'keys: ${stroke.keyIds.length}',
        ]);
      }
      final String? previous = signatureOwner[stroke.signature];
      if (previous != null) {
        throw BuildException('Two briefs share a chord.', <String>[
          '$previous and $word both use ${stroke.format()}',
        ]);
      }
      signatureOwner[stroke.signature] = word;
      assignments[word] = _Assignment(
        word: word,
        stroke: stroke,
        outline: brief.outline,
        brief: brief,
        phones: cmu.phoneText(
              word,
              variant: RuleEngine.preferredVariants[word.toLowerCase()] ?? 1,
            ) ??
            '',
        variant: 'brief',
        collisionResolved: false,
      );
    }

    // 2. Rules fill the remaining words in source-list order.
    for (final String word in words) {
      if (assignments.containsKey(word)) {
        continue;
      }
      final List<RuleCandidate> candidates = rules.candidatesFor(word);
      if (candidates.isEmpty) {
        throw BuildException(
          'Could not generate a rule-based outline for "$word".',
          <String>['CMUdict pronunciation missing or unusable'],
        );
      }
      RuleCandidate? chosen;
      var resolved = false;
      for (final RuleCandidate candidate in candidates) {
        if (signatureOwner.containsKey(candidate.signature)) {
          resolved = true;
          continue;
        }
        chosen = candidate;
        break;
      }
      chosen ??= _fallbackCandidate(word, candidates.first, signatureOwner);
      if (chosen == null) {
        throw BuildException(
          'Could not find a unique single-stroke outline for "$word".',
          <String>['Exhausted rule variants and right-hand tags'],
        );
      }
      final Stroke stroke = Stroke.parse(chosen.outline);
      signatureOwner[chosen.signature] = word;
      assignments[word] = _Assignment(
        word: word,
        stroke: stroke,
        outline: chosen.outline,
        brief: null,
        phones: cmu.phoneText(
              word,
              variant: RuleEngine.preferredVariants[word.toLowerCase()] ?? 1,
            ) ??
            '',
        variant: chosen.variant,
        collisionResolved: resolved || !chosen.isBase,
        targetPhone: chosen.targetPhone,
        onsetPhones: chosen.onsetPhones,
        codaPhones: chosen.codaPhones,
      );
    }

    // 3. Optional two-stroke expansions for words with more than one
    // stressed vowel. dictionary.json remains a single-stroke teaching set.
    final Map<String, String> multiStroke = <String, String>{};
    for (final String word in words) {
      final _Assignment assignment = assignments[word]!;
      if (assignment.brief != null) {
        continue;
      }
      final Pronunciation? pronunciation = cmu.pronunciation(
        word,
        preferredVariant: RuleEngine.preferredVariants[word.toLowerCase()] ?? 1,
      );
      if (pronunciation == null) {
        continue;
      }
      final String? expanded = artOfChordingMultiStroke[word.toLowerCase()] ??
          _multiStrokeFor(word, pronunciation, rules);
      if (expanded != null) {
        multiStroke[word] = expanded;
        assignment.multiStroke = <String>[expanded];
      }
    }

    // Record the plain rule form for every word, including briefs. This makes
    // the `changed` flag auditable instead of inferring it from `brief`.
    for (final String word in words) {
      final _Assignment assignment = assignments[word]!;
      final List<RuleCandidate> candidates = rules.candidatesFor(word);
      if (candidates.isNotEmpty) {
        assignment.plainRule ??= candidates.first.outline;
        assignment.plainSignature ??= candidates.first.signature;
      }
    }

    // 4. Materialise entries in source-list order.
    final List<DictionaryEntry> entries = <DictionaryEntry>[];
    for (final String word in words) {
      entries.add(assignments[word]!.toEntry());
    }

    final Map<String, String> dictionary = <String, String>{
      for (final DictionaryEntry entry in entries) entry.word: entry.outline,
    };

    final List<CheckResult> checks = _runChecks(
      words: words,
      entries: entries,
      dictionary: dictionary,
      multiStroke: multiStroke,
    );
    final bool allPassed = checks.every((CheckResult check) => check.passed);

    final String dictionaryJson = '${_encode(dictionary)}\n';
    final String multiStrokeJson = '${_encode(multiStroke)}\n';
    final String entriesJson =
        '${_encode(entries.map((DictionaryEntry e) => e.toProvenanceJson()).toList(growable: false))}\n';
    final String selfCheck = _selfCheckMarkdown(
      words: words,
      entries: entries,
      dictionary: dictionary,
      multiStroke: multiStroke,
      checks: checks,
    );

    final Map<String, _OutputHash> outputHashes = <String, _OutputHash>{
      'data/dictionary.json': _hashText(dictionaryJson),
      'data/multi_stroke.json': _hashText(multiStrokeJson),
      'provenance/entries.json': _hashText(entriesJson),
      'validation/self_check.md': _hashText(selfCheck),
    };

    final String date = _buildDate();
    final String commit = _gitCommit();
    final Map<String, int> usage = _sourceUsage(entries);
    final Map<String, Object?> manifest = <String, Object?>{
      'format': 'steno-start-dictionary-manifest',
      'version': 1,
      'license': 'CC-BY-SA-4.0',
      'generator': <String, Object?>{
        'name': generatorName,
        'version': generatorVersion,
        'commit': commit,
      },
      'command': buildCommand,
      'date': date,
      'dateBasis':
          'Latest source retrieval date; override with SOURCE_DATE_EPOCH.',
      'referenceIds': <String>[
        SourceIds.top100,
        SourceIds.briefIdeas,
        SourceIds.cheatSheets,
        SourceIds.theory,
        SourceIds.artOfChording,
      ],
      'counts': <String, Object?>{
        'words': words.length,
        'dictionaryEntries': dictionary.length,
        'uniqueSignatures': dictionary.values
            .map((String outline) => Stroke.parse(outline).signature)
            .toSet()
            .length,
        'briefEntries': entries.where((DictionaryEntry e) => e.brief).length,
        'ruleEntries': entries.where((DictionaryEntry e) => !e.brief).length,
        'changedEntries':
            entries.where((DictionaryEntry e) => e.changed).length,
        'collisionResolved':
            entries.where((DictionaryEntry e) => e.collisionResolved).length,
        'multiStrokeEntries': multiStroke.length,
        'sourceIdsUsed': usage.keys.length,
      },
      'sources': <Map<String, Object?>>[
        for (final SourceRecord source in _allowedSources)
          <String, Object?>{
            ...source.toJson(),
            'entryCount': usage[source.id] ?? 0,
          },
      ],
      'outputs': <String, Object?>{
        for (final MapEntry<String, _OutputHash> entry in outputHashes.entries)
          entry.key: entry.value.toJson(),
      },
      'notes': <String>[
        'Generated from CMUdict pronunciation, the Wikipedia Stenotype chart, '
            'the open Plover Wiki theory pages and the archived Art of '
            'Chording text listed in sources.json.',
        'No Plover main.json, GPL dictionary or proprietary dictionary data '
            'is used.',
        'Art of Chording is used through the Wayback archive recorded in '
            'sources/art-of-chording/web-archive/pages.json; the archive '
            'footer states CC BY-SA 4.0.',
        'dictionary.json is a single-stroke teaching set. multi_stroke.json '
            'records optional two-stroke expansions for words with more than '
            'one stressed vowel.',
        'Accuracy against any external Plover reference is not claimed here; '
            'the parent project runs that black-box backtest.',
      ],
    };
    final String manifestJson = '${_encode(manifest)}\n';
    outputHashes['data/manifest.json'] = _hashText(manifestJson);

    final List<Map<String, Object?>> inputs = _inputHashes();
    final Map<String, Object?> build = <String, Object?>{
      'format': 'steno-start-build',
      'version': 1,
      'generator': <String, Object?>{
        'name': generatorName,
        'version': generatorVersion,
        'commit': commit,
      },
      'command': buildCommand,
      'date': date,
      'referenceIds': <String>[
        SourceIds.top100,
        SourceIds.briefIdeas,
        SourceIds.cheatSheets,
        SourceIds.theory,
        SourceIds.artOfChording,
      ],
      'runtime': <String, Object?>{
        'dart': Platform.version.split(' ').first,
        'platform': Platform.operatingSystem,
      },
      'counts': manifest['counts'],
      'sourceRegistry': <String, Object?>{
        'path': 'sources/sources.json',
        'sha256': _hashFile(File(_path('sources/sources.json'))).sha256,
      },
      'inputs': inputs,
      'outputs': <String, Object?>{
        for (final MapEntry<String, _OutputHash> entry in outputHashes.entries)
          entry.key: entry.value.toJson(),
      },
      'notes': <String>[
        'All paths are relative to the repository root.',
        'Input hashes cover the allowed source files, the clean engine and '
            'the generator source.',
        'Build date is deterministic: it is the latest source retrieval date '
            'unless SOURCE_DATE_EPOCH is set.',
      ],
    };
    final String buildJson = '${_encode(build)}\n';

    if (write) {
      _write('data/dictionary.json', dictionaryJson);
      _write('data/multi_stroke.json', multiStrokeJson);
      _write('data/manifest.json', manifestJson);
      _write('provenance/entries.json', entriesJson);
      _write('provenance/build.json', buildJson);
      _write('validation/self_check.md', selfCheck);
    }

    final int briefCount = entries.where((DictionaryEntry e) => e.brief).length;
    final int ruleCount = entries.length - briefCount;
    final int resolvedCount =
        entries.where((DictionaryEntry e) => e.collisionResolved).length;
    final String summary = allPassed
        ? 'Built ${entries.length} words: $briefCount briefs, $ruleCount '
            'rule-derived, $resolvedCount collision-resolved, '
            '${multiStroke.length} multi-stroke; ${dictionary.length} unique '
            'single strokes. ALL CHECKS PASSED.'
        : 'Built ${entries.length} words but some checks FAILED.';

    return BuildResult(
      entries: entries,
      dictionary: dictionary,
      multiStroke: multiStroke,
      dictionaryJson: dictionaryJson,
      multiStrokeJson: multiStrokeJson,
      entriesJson: entriesJson,
      manifestJson: manifestJson,
      buildJson: buildJson,
      selfCheck: selfCheck,
      checks: checks,
      summary: summary,
    );
  }

  void _validateSources() {
    final List<String> errors = <String>[];
    for (final SourceRecord source in _allowedSources) {
      final File file = File(_path(source.file));
      if (!file.existsSync()) {
        errors.add('${source.id}: missing ${source.file}');
        continue;
      }
      final _OutputHash actual = _hashFile(file);
      if (actual.sha256 != source.sha256 || actual.bytes != source.bytes) {
        errors.add(
          '${source.id}: hash mismatch for ${source.file} '
          '(registry ${source.sha256}, actual ${actual.sha256})',
        );
      }
      for (final String path in source.files) {
        if (!File(_path(path)).existsSync()) {
          errors.add('${source.id}: missing ${path}');
        }
      }
      if (source.id == 'art-of-chording-website') {
        errors.addAll(_validateArchivePages(source));
      }
    }
    if (errors.isNotEmpty) {
      throw BuildException('Source registry validation failed.', errors);
    }
  }

  /// Verify every page-level HTML and text hash in the Art of Chording
  /// manifest. Checking only the manifest hash would let a swapped page pass.
  List<String> _validateArchivePages(SourceRecord source) {
    final List<String> errors = <String>[];
    final Map<String, dynamic> manifest =
        jsonDecode(File(_path(source.file)).readAsStringSync())
            as Map<String, dynamic>;
    final List<dynamic> pages = manifest['pages'] as List<dynamic>;
    for (final dynamic raw in pages) {
      final Map<String, dynamic> page = raw as Map<String, dynamic>;
      final String id = page['path'] as String;
      for (final MapEntry<String, String> pair in <String, String>{
        'html': 'sha256',
        'text': 'textSha256',
      }.entries) {
        final String path = page[pair.key] as String;
        final String? expected = page[pair.value] as String?;
        final File file = File(_path(path));
        if (!file.existsSync()) {
          errors.add('${source.id}: missing $path');
          continue;
        }
        if (expected == null || expected.isEmpty) {
          errors.add('${source.id}: $id has no ${pair.value}');
          continue;
        }
        if (_hashFile(file).sha256 != expected) {
          errors.add('${source.id}: $id ${pair.key} hash mismatch');
        }
      }
    }
    return errors;
  }

  List<String> _readWords() {
    final File file = File(_path('data/source_words.txt'));
    if (!file.existsSync()) {
      throw BuildException('Missing data/source_words.txt');
    }
    final List<String> words = file
        .readAsLinesSync()
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);
    final Set<String> seen = <String>{};
    final List<String> duplicates = <String>[];
    for (final String word in words) {
      if (!seen.add(word.toLowerCase())) {
        duplicates.add(word);
      }
    }
    if (duplicates.isNotEmpty) {
      throw BuildException(
        'Duplicate words in data/source_words.txt.',
        duplicates,
      );
    }
    return words;
  }

  RuleCandidate? _fallbackCandidate(
    String word,
    RuleCandidate base,
    Map<String, String> used,
  ) {
    // Search right-hand tag combinations in a deterministic order. There are
    // 2^10 - 1 = 1023 single/tag combinations, far more than the handful of
    // homophone collisions this dictionary contains.
    for (int mask = 1; mask < (1 << rightTagOrder.length); mask++) {
      final Set<int> ids = <int>{...base.keyIds};
      bool changed = false;
      for (int bit = 0; bit < rightTagOrder.length; bit++) {
        if ((mask & (1 << bit)) != 0) {
          final int key = rightTagOrder[bit];
          if (!ids.contains(key)) {
            ids.add(key);
            changed = true;
          }
        }
      }
      if (!changed) {
        continue;
      }
      final Stroke stroke;
      try {
        stroke = Stroke.fromKeyIds(ids);
      } on RangeError {
        continue;
      }
      final String outline = stroke.format();
      final Stroke reparsed;
      try {
        reparsed = Stroke.parse(outline);
      } on FormatException {
        continue;
      }
      if (reparsed.signature != stroke.signature) {
        continue;
      }
      if (used.containsKey(stroke.signature)) {
        continue;
      }
      return RuleCandidate(
        outline: outline,
        signature: stroke.signature,
        keyIds: stroke.keyIds.toSet(),
        variant: 'fallback-tags-$mask',
        mergedEarlier: false,
        targetPhone: base.targetPhone,
        onsetPhones: base.onsetPhones,
        codaPhones: base.codaPhones,
      );
    }
    return null;
  }

  String? _multiStrokeFor(
    String word,
    Pronunciation pronunciation,
    RuleEngine rules,
  ) {
    final List<Phone> phones = pronunciation.phones;
    final List<int> stressed = <int>[
      for (int i = 0; i < phones.length; i++)
        if (phones[i].isVowel &&
            (phones[i].stress == 1 || phones[i].stress == 2))
          i,
    ];
    if (stressed.length < 2) {
      return null;
    }
    final List<int> vowels = <int>[
      for (int i = 0; i < phones.length; i++)
        if (phones[i].isVowel) i,
    ];
    final int splitVowel = stressed[1];
    final int position = vowels.indexOf(splitVowel);
    if (position <= 0) {
      return null;
    }
    final int previousVowel = vowels[position - 1];
    final int between = splitVowel - previousVowel - 1;
    int split = previousVowel + 1 + (between ~/ 2);
    if (split <= previousVowel) {
      split = splitVowel;
    }
    if (split <= 0 || split >= phones.length) {
      return null;
    }

    final RuleCandidate? first = rules.buildPart(
      word,
      phones.sublist(0, split),
      variant: 'multi-1',
    );
    final RuleCandidate? second = rules.buildPart(
      word,
      phones.sublist(split),
      variant: 'multi-2',
    );
    if (first == null || second == null) {
      return null;
    }
    final String outline = '${first.outline}/${second.outline}';
    for (final String part in outline.split('/')) {
      final Stroke stroke;
      try {
        stroke = Stroke.parse(part);
      } on FormatException {
        return null;
      }
      if (stroke.keyIds.isEmpty || stroke.keyIds.length > stenoKeyCount) {
        return null;
      }
      if (Stroke.parse(stroke.format()).signature != stroke.signature) {
        return null;
      }
    }
    return outline;
  }

  List<CheckResult> _runChecks({
    required List<String> words,
    required List<DictionaryEntry> entries,
    required Map<String, String> dictionary,
    required Map<String, String> multiStroke,
  }) {
    final List<CheckResult> checks = <CheckResult>[];
    final List<String> parseErrors = <String>[];
    final List<String> keyCountErrors = <String>[];
    final List<String> duplicateKeyErrors = <String>[];
    final List<String> roundTripErrors = <String>[];
    final Map<String, List<String>> bySignature = <String, List<String>>{};
    final Map<String, int> keyCounts = <String, int>{};

    for (final DictionaryEntry entry in entries) {
      final Stroke stroke;
      try {
        stroke = Stroke.parse(entry.outline);
      } on FormatException catch (error) {
        parseErrors.add('${entry.word}: ${error.message}');
        continue;
      }
      keyCounts[entry.word] = stroke.keyIds.length;
      if (stroke.keyIds.length < 1 || stroke.keyIds.length > stenoKeyCount) {
        keyCountErrors.add(
          '${entry.word}: ${stroke.keyIds.length} keys (${entry.outline})',
        );
      }
      if (stroke.keyIds.toSet().length != stroke.keyIds.length) {
        duplicateKeyErrors.add('${entry.word}: ${entry.outline}');
      }
      final Stroke reparsed = Stroke.parse(stroke.format());
      if (reparsed.signature != stroke.signature ||
          reparsed.format() != entry.outline) {
        roundTripErrors.add('${entry.word}: ${entry.outline}');
      }
      bySignature
          .putIfAbsent(stroke.signature, () => <String>[])
          .add(entry.word);
    }

    final List<String> duplicateSignatures = <String>[
      for (final MapEntry<String, List<String>> entry in bySignature.entries)
        if (entry.value.length > 1) '${entry.key}: ${entry.value.join(', ')}',
    ];

    final Set<String> wordSet = words.toSet();
    final Set<String> dictSet = dictionary.keys.toSet();
    final List<String> missing = <String>[
      for (final String word in words)
        if (!dictSet.contains(word)) word,
    ];
    final List<String> extra = <String>[
      for (final String word in dictSet)
        if (!wordSet.contains(word)) word,
    ];

    final List<String> sourceErrors = <String>[];
    final Set<String> usedSourceIds = <String>{};
    for (final DictionaryEntry entry in entries) {
      if (entry.sourceIds.isEmpty) {
        sourceErrors.add('${entry.word}: no source ids');
      }
      for (final String id in entry.sourceIds) {
        if (!_registry.containsKey(id)) {
          sourceErrors.add('${entry.word}: unknown source id $id');
        }
        usedSourceIds.add(id);
      }
    }

    final List<String> multiErrors = <String>[];
    for (final MapEntry<String, String> entry in multiStroke.entries) {
      if (!wordSet.contains(entry.key)) {
        multiErrors.add('${entry.key}: not in source word list');
      }
      final List<String> parts = entry.value.split('/');
      if (parts.length < 2) {
        multiErrors.add('${entry.key}: not multi-stroke');
      }
      for (final String part in parts) {
        final Stroke stroke;
        try {
          stroke = Stroke.parse(part);
        } on FormatException catch (error) {
          multiErrors.add('${entry.key}: ${error.message}');
          continue;
        }
        if (stroke.keyIds.isEmpty || stroke.keyIds.length > stenoKeyCount) {
          multiErrors.add('${entry.key}: ${part} has bad key count');
        }
        if (Stroke.parse(stroke.format()).signature != stroke.signature) {
          multiErrors.add('${entry.key}: ${part} is not faithful');
        }
      }
    }

    final int minKeys = keyCounts.values.isEmpty
        ? 0
        : keyCounts.values.reduce((int a, int b) => min(a, b));
    final int maxKeys = keyCounts.values.isEmpty
        ? 0
        : keyCounts.values.reduce((int a, int b) => max(a, b));

    checks.add(
      CheckResult(
        'Every dictionary stroke parses',
        parseErrors.isEmpty,
        parseErrors.isEmpty
            ? '${entries.length}/${entries.length} strokes parsed by the clean engine.'
            : '${parseErrors.length} failures: ${parseErrors.take(5).join('; ')}',
      ),
    );
    checks.add(
      CheckResult(
        'Every stroke has 1-22 keys',
        keyCountErrors.isEmpty,
        keyCountErrors.isEmpty
            ? 'Key counts are between $minKeys and $maxKeys.'
            : keyCountErrors.take(5).join('; '),
      ),
    );
    checks.add(
      CheckResult(
        'No duplicate keys within a stroke',
        duplicateKeyErrors.isEmpty,
        duplicateKeyErrors.isEmpty
            ? 'All ${entries.length} strokes are sets of distinct physical keys.'
            : duplicateKeyErrors.take(5).join('; '),
      ),
    );
    checks.add(
      CheckResult(
        'All 500 signatures are unique',
        duplicateSignatures.isEmpty,
        duplicateSignatures.isEmpty
            ? '${bySignature.length}/${entries.length} signatures are unique.'
            : duplicateSignatures.take(5).join('; '),
      ),
    );
    checks.add(
      CheckResult(
        'All source words are covered exactly once',
        missing.isEmpty && extra.isEmpty && dictionary.length == words.length,
        missing.isEmpty && extra.isEmpty
            ? '${dictionary.length}/${words.length} words present; no extras.'
            : 'missing: ${missing.join(', ')}; extra: ${extra.join(', ')}',
      ),
    );
    checks.add(
      CheckResult(
        'Every stroke round-trips through canonical formatting',
        roundTripErrors.isEmpty,
        roundTripErrors.isEmpty
            ? 'All outlines round-trip through the canonical engine formatter.'
            : roundTripErrors.take(5).join('; '),
      ),
    );
    checks.add(
      CheckResult(
        'Every entry has at least one registered source id',
        sourceErrors.isEmpty,
        sourceErrors.isEmpty
            ? '${usedSourceIds.length} registered source ids are used.'
            : sourceErrors.take(5).join('; '),
      ),
    );
    checks.add(
      CheckResult(
        'Multi-stroke parts parse and are 1-22 keys',
        multiErrors.isEmpty,
        multiErrors.isEmpty
            ? '${multiStroke.length} multi-stroke expansions checked.'
            : multiErrors.take(5).join('; '),
      ),
    );

    return checks;
  }

  String _selfCheckMarkdown({
    required List<String> words,
    required List<DictionaryEntry> entries,
    required Map<String, String> dictionary,
    required Map<String, String> multiStroke,
    required List<CheckResult> checks,
  }) {
    final List<String> lines = <String>[
      '# Self-check',
      '',
      'This file is generated by `generator/bin/generate.dart`. It checks the '
          'generated dictionary with the clean engine in `engine/`. It does '
          '**not** claim accuracy against Plover or any other dictionary; the '
          'parent project runs the black-box backtest separately.',
      '',
      '## Result',
      '',
      '| Check | Result | Detail |',
      '|---|---|---|',
      for (final CheckResult check in checks)
        '| ${check.name} | ${check.mark} | ${_md(check.detail)} |',
      '',
      'Overall: **${checks.every((CheckResult c) => c.passed) ? 'PASS' : 'FAIL'}**',
      '',
      '## Coverage',
      '',
      '- Source words: ${words.length}',
      '- Dictionary entries: ${dictionary.length}',
      '- Unique signatures: '
          '${dictionary.values.map((String o) => Stroke.parse(o).signature).toSet().length}',
      '- Brief entries: ${entries.where((DictionaryEntry e) => e.brief).length}',
      '- Rule-derived entries: '
          '${entries.where((DictionaryEntry e) => !e.brief).length}',
      '- Collision-resolved entries: '
          '${entries.where((DictionaryEntry e) => e.collisionResolved).length}',
      '- Multi-stroke expansions: ${multiStroke.length}',
      '',
      '## Key counts',
      '',
      '| Number of keys | Entries |',
      '|---|---|',
      for (final int count in (<int>{
        ...entries
            .map((DictionaryEntry e) => Stroke.parse(e.outline).keyIds.length)
            .toSet(),
      }).toList()
        ..sort())
        '| $count | '
            '${entries.where((DictionaryEntry e) => Stroke.parse(e.outline).keyIds.length == count).length} |',
      '',
      '## Art of Chording citations',
      '',
      'The archived Art of Chording text (CC BY-SA 4.0) is cited per entry '
          'where its examples or briefs are used. Conceptual illustrations '
          'that are not written in the steno alphabet are not treated as '
          'outlines.',
      '',
      '| Word | Outline | Archived page |',
      '|---|---|---|',
      for (final DictionaryEntry entry in entries)
        if (entry.sourceIds.contains(SourceIds.artOfChording))
          '| ${_md(entry.word)} | `${entry.outline}` | '
              '${_md(artOfChordingExamplePages[entry.word.toLowerCase()] ?? (entry.word.toLowerCase() == 'outside' ? 'multistroke/prefixes-and-suffixes' : 'archived page'))} |',
      '',
      '## Entries changed from the plain rule',
      '',
      'These outlines differ from the plain rule signature. The comparison is '
          'recorded as `plainRule` and `plainSignature` in the provenance; a '
          'brief that happens to equal the plain rule is not marked changed.',
      '',
      '| Word | Outline | Variant | Source ids |',
      '|---|---|---|---|',
      for (final DictionaryEntry entry in entries)
        if (entry.changed)
          '| ${_md(entry.word)} | `${entry.outline}` | ${_md(entry.variant)} | '
              '${entry.sourceIds.join(', ')} |',
      '',
      '## Method notes',
      '',
      '- Each word is assigned exactly one single-stroke outline in '
          '`data/dictionary.json`.',
      '- `data/multi_stroke.json` is an optional expansion layer for words '
          'with more than one stressed vowel; it is not needed to cover the '
          'word list.',
      '- Briefs are reserved before rules. The briefs layer is documented in '
          '`generator/lib/src/briefs.dart` and `generator/RULES.md`.',
      '- Rule-derived entries cite `cmudict`, `wikipedia-stenotype`, '
          '`steno-start-word-list` and `steno-start-rules`; entries whose '
          'exact example appears in the archived Art of Chording text also '
          'cite `art-of-chording-website`.',
      '- The generator does not read or include Plover `main.json`, GPL '
          'dictionaries or proprietary dictionary data. The Plover Wiki pages '
          'are public theory references, not the GPL dictionary.',
      '',
    ];
    return lines.join('\n');
  }

  Map<String, int> _sourceUsage(List<DictionaryEntry> entries) {
    final Map<String, int> usage = <String, int>{};
    for (final DictionaryEntry entry in entries) {
      for (final String id in entry.sourceIds) {
        usage[id] = (usage[id] ?? 0) + 1;
      }
    }
    return Map<String, int>.fromEntries(
      usage.entries.toList()
        ..sort(
          (MapEntry<String, int> a, MapEntry<String, int> b) =>
              a.key.compareTo(b.key),
        ),
    );
  }

  List<Map<String, Object?>> _inputHashes() {
    final List<File> files = <File>[];
    for (final SourceRecord source in _allowedSources) {
      files.add(File(_path(source.file)));
      for (final String path in source.files) {
        files.add(File(_path(path)));
      }
    }
    files.add(File(_path('sources/sources.json')));
    files.add(File(_path('engine/pubspec.yaml')));
    files.addAll(_dartFiles(_path('engine/lib')));
    files.add(File(_path('generator/pubspec.yaml')));
    files.addAll(_dartFiles(_path('generator/lib')));
    files.addAll(_dartFiles(_path('generator/bin')));
    files.add(File(_path('generator/RULES.md')));

    final Map<String, File> unique = <String, File>{};
    for (final File file in files) {
      if (file.existsSync()) {
        unique[_relative(file)] = file;
      }
    }
    final List<String> paths = unique.keys.toList()..sort();
    return <Map<String, Object?>>[
      for (final String path in paths)
        <String, Object?>{'path': path, ..._hashFile(unique[path]!).toJson()},
    ];
  }

  List<File> _dartFiles(String path) {
    final Directory directory = Directory(path);
    if (!directory.existsSync()) {
      return <File>[];
    }
    return directory
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((File file) => file.path.endsWith('.dart'))
        .toList(growable: false);
  }

  String _buildDate() {
    final String? epoch = Platform.environment['SOURCE_DATE_EPOCH'];
    if (epoch != null && epoch.isNotEmpty) {
      final int? seconds = int.tryParse(epoch);
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000,
          isUtc: true,
        ).toIso8601String().substring(0, 10);
      }
    }
    final List<String> dates = _allowedSources
        .map((SourceRecord source) => source.retrieved)
        .where((String date) => date.isNotEmpty)
        .toList()
      ..sort();
    if (dates.isNotEmpty) {
      return dates.last;
    }
    return DateTime.now().toUtc().toIso8601String().substring(0, 10);
  }

  String _gitCommit() {
    try {
      final ProcessResult result = Process.runSync(
          'git',
          <String>[
            '-c',
            'safe.directory=*',
            'rev-parse',
            'HEAD',
          ],
          workingDirectory: root.path);
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
    } on Object {
      // Fall through to the explicit unknown marker.
    }
    return 'unknown';
  }

  void _write(String relative, String contents) {
    final File file = File(_path(relative));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
  }

  _OutputHash _hashFile(File file) {
    final List<int> bytes = file.readAsBytesSync();
    return _OutputHash(sha256: sha256Hex(bytes), bytes: bytes.length);
  }

  _OutputHash _hashText(String text) {
    final List<int> bytes = utf8.encode(text);
    return _OutputHash(sha256: sha256Hex(bytes), bytes: bytes.length);
  }

  static String _encode(Object? value) =>
      JsonEncoder.withIndent('  ').convert(value);

  static String _md(String text) =>
      text.replaceAll('|', r'\|').replaceAll('\n', ' ').replaceAll('\r', ' ');
}

class _Assignment {
  _Assignment({
    required this.word,
    required this.stroke,
    required this.outline,
    required this.brief,
    required this.phones,
    required this.variant,
    required this.collisionResolved,
    this.targetPhone,
    this.onsetPhones = const <String>[],
    this.codaPhones = const <String>[],
  });

  final String word;
  final Stroke stroke;

  /// The outline as written in the source, which may be a documented
  /// non-canonical form such as the Plover Wiki's `TP-R` for "for".
  final String outline;
  final Brief? brief;
  final String phones;
  final String variant;
  final bool collisionResolved;
  final String? targetPhone;
  final List<String> onsetPhones;
  final List<String> codaPhones;
  List<String> multiStroke = const <String>[];
  String? plainRule;
  String? plainSignature;

  DictionaryEntry toEntry() {
    final bool isBrief = brief != null;
    final bool changed = isBrief
        ? (plainSignature != null && stroke.signature != plainSignature)
        : (collisionResolved || variant != 'base');
    final List<String> sourceIds = isBrief
        ? List<String>.of(brief!.sourceIds)
        : <String>[
            SourceIds.cmudict,
            SourceIds.wikipedia,
            SourceIds.rules,
          ];
    final String? aocExample = artOfChordingExamples[word.toLowerCase()];
    final bool aocExactMatch = aocExample == outline;
    if (!isBrief &&
        aocExactMatch &&
        !sourceIds.contains(SourceIds.artOfChording)) {
      sourceIds.insert(0, SourceIds.artOfChording);
    }
    final bool aocMulti = artOfChordingMultiStroke.containsKey(
      word.toLowerCase(),
    );
    if (aocMulti && !sourceIds.contains(SourceIds.artOfChording)) {
      sourceIds.insert(0, SourceIds.artOfChording);
    }

    final String description;
    if (isBrief) {
      final StringBuffer buffer = StringBuffer(brief!.description);
      if (brief!.wikiForm != null && brief!.wikiForm != brief!.outline) {
        buffer.write(
          ' Wiki form: ${brief!.wikiForm}; canonical engine form: '
          '${brief!.outline}.',
        );
      }
      description = buffer.toString();
    } else {
      final StringBuffer buffer = StringBuffer()
        ..write('Phoneme rules v1: CMUdict ')
        ..write('[$phones] -> target ')
        ..write(targetPhone ?? '?')
        ..write('; onset ')
        ..write(onsetPhones.isEmpty ? 'none' : onsetPhones.join(' '))
        ..write('; coda ')
        ..write(codaPhones.isEmpty ? 'none' : codaPhones.join(' '))
        ..write('. Variant: $variant.');
      if (aocExactMatch) {
        buffer.write(
          ' The Art of Chording archive ('
          '${artOfChordingExamplePages[word.toLowerCase()] ?? 'archived page'}'
          ') supports the same $aocExample form for "$word".',
        );
      }
      if (aocMulti) {
        buffer.write(
          ' The Art of Chording archive '
          '(multistroke/prefixes-and-suffixes) gives '
          '${artOfChordingMultiStroke[word.toLowerCase()]} for "$word"; '
          'that form is recorded in data/multi_stroke.json.',
        );
      }
      description = buffer.toString();
    }
    return DictionaryEntry(
      word: word,
      outline: outline,
      signature: stroke.signature,
      sourceIds: sourceIds,
      description: description,
      changed: changed,
      brief: isBrief,
      collisionResolved: collisionResolved,
      variant: variant,
      phones: phones,
      multiStroke: multiStroke,
      plainRule: plainRule ?? outline,
      plainSignature: plainSignature ?? stroke.signature,
    );
  }
}

class _OutputHash {
  const _OutputHash({required this.sha256, required this.bytes});

  final String sha256;
  final int bytes;

  Map<String, Object?> toJson() => <String, Object?>{
        'sha256': sha256,
        'bytes': bytes,
      };
}
