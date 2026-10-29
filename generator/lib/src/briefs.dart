/// Documented briefs layer.
///
/// A brief is a deliberate short outline for a word. Briefs are used before
/// the pronunciation rules. Every brief carries the open source ids that
/// support it. Briefs adapted from the Plover Wiki are not copied from the
/// GPL `main.json` dictionary; they are examples published on the wiki pages.
library;

/// Source ids. These must exist in `sources/sources.json`.
class SourceIds {
  static const String cmudict = 'cmudict';
  static const String wikipedia = 'wikipedia-stenotype';
  static const String top100 = 'plover-wiki-top-100';
  static const String briefIdeas = 'plover-wiki-brief-ideas';
  static const String cheatSheets = 'plover-wiki-cheat-sheets';
  static const String theory = 'plover-wiki-theory';
  static const String wordList = 'steno-start-word-list';
  static const String artOfChording = 'art-of-chording-website';
  static const String rules = 'steno-start-rules';
}

/// A brief and the references that justify it.
class Brief {
  const Brief({
    required this.outline,
    required this.sourceIds,
    required this.description,
    this.wikiForm,
    this.page,
  });

  /// Canonical outline, as produced by the clean engine's formatter.
  final String outline;

  /// Registered source ids supporting this brief.
  final List<String> sourceIds;

  /// Human-readable description for provenance/entries.json.
  final String description;

  /// The form as written on the wiki page, when it differs from [outline].
  final String? wikiForm;

  /// Wiki page id, e.g. `plover-wiki-top-100`.
  final String? page;
}

const List<String> _top100Sources = <String>[
  SourceIds.top100,
];

const List<String> _briefIdeaSources = <String>[
  SourceIds.briefIdeas,
];

const List<String> _artOfChordingSources = <String>[
  SourceIds.artOfChording,
];

/// Exact examples published in the archived Art of Chording text.
///
/// Only forms that are spelled out as steno outlines on the archived pages are
/// listed here. Conceptual "BAER" style homophone illustrations are *not*
/// treated as outlines because they are not written in the steno alphabet.
const Map<String, String> artOfChordingExamples = <String, String>{
  'a': 'AEU',
  'air': 'AEUR',
  'always': 'AULS',
  'and': 'SKP',
  'are': 'R',
  'around': 'ARPBD',
  'be': '-B',
  'can': 'K',
  'cat': 'KAT',
  'day': 'TKAEU',
  'every': 'EFR',
  'he': 'HE',
  'make': 'PHAEUBG',
  'oil': 'OEUL',
  'or': 'OR',
  'paper': 'PAEUP',
  'pay': 'PAEU',
  'rat': 'RAT',
  'remember': 'RER',
  'she': 'SHE',
  'so': 'SO',
  'start': 'START',
  'stay': 'STAEU',
  'take': 'TAEUBG',
  'the': '-T',
  'their': 'THAEUR',
  'there': 'THR',
  'they': 'THE',
  'to': 'TO',
  'we': 'WE',
  'with': 'W',
  'you': 'U',
};

/// The archived page or chapter that supports each exact example above.
const Map<String, String> artOfChordingExamplePages = <String, String>{
  'a': 'layout/bottom-row',
  'air': 'sounds/ay_oy',
  'always': 'introduction/how-steno-works',
  'and': 'layout/bottom-row',
  'are': 'layout/bottom-row',
  'around': 'multistroke/prefixes-and-suffixes',
  'be': 'layout/bottom-row',
  'can': 'layout/bottom-row',
  'cat': 'introduction/how-steno-works',
  'day': 'sounds/ay_oy',
  'every': 'introduction/how-steno-works',
  'he': 'layout/bottom-row',
  'make': 'sounds/ay_oy',
  'oil': 'sounds/ay_oy',
  'or': 'layout/bottom-row',
  'paper': 'sounds/ay_oy',
  'pay': 'sounds/ay_oy',
  'rat': 'layout/chorded-keyboard',
  'remember': 'introduction/how-steno-works',
  'she': 'layout/bottom-row',
  'so': 'layout/bottom-row',
  'start': 'introduction/how-steno-works',
  'stay': 'sounds/ay_oy',
  'take': 'sounds/ay_oy',
  'the': 'introduction/how-steno-works',
  'their': 'sounds/ay_oy',
  'there': 'sounds/ay_oy',
  'they': 'sounds/ay_oy',
  'to': 'layout/bottom-row',
  'we': 'layout/bottom-row',
  'with': 'introduction/how-steno-works',
  'you': 'introduction/how-steno-works',
};

/// Multi-stroke forms explicitly given in the archived Art of Chording text.
const Map<String, String> artOfChordingMultiStroke = <String, String>{
  'outside': 'OUT/SEUD',
};

/// Entries that differ from the plain one-chord rule but are not briefs in the
/// ordinary sense: they are exact AoC examples.
const Map<String, Brief> artOfChordingBriefs = <String, Brief>{
  'are': Brief(
    outline: 'R',
    sourceIds: _artOfChordingSources,
    description:
        "Art of Chording, layout/bottom-row (archived): 'R- or -R are'. "
        'The left-hand R is used here; the right-hand -R is the same word.',
    wikiForm: 'R-',
    page: SourceIds.artOfChording,
  ),
  'always': Brief(
    outline: 'AULS',
    sourceIds: _artOfChordingSources,
    description:
        "Art of Chording, introduction/how-steno-works (archived): the "
        "breakdown gives AULS for 'always'.",
    wikiForm: 'AULS',
    page: SourceIds.artOfChording,
  ),
  'every': Brief(
    outline: 'EFR',
    sourceIds: _artOfChordingSources,
    description:
        "Art of Chording, introduction/how-steno-works (archived): the "
        "breakdown gives EFR for 'every'.",
    wikiForm: 'EFR',
    page: SourceIds.artOfChording,
  ),
  'remember': Brief(
    outline: 'RER',
    sourceIds: _artOfChordingSources,
    description:
        "Art of Chording, introduction/how-steno-works (archived): RER is "
        "the brief given for 'remember'.",
    wikiForm: 'RER',
    page: SourceIds.artOfChording,
  ),
  'around': Brief(
    outline: 'ARPBD',
    sourceIds: _artOfChordingSources,
    description:
        "Art of Chording, multistroke/prefixes-and-suffixes (archived): "
        "ARPBD is the single-stroke form given for 'around' (a^ + round).",
    wikiForm: 'ARPBD',
    page: SourceIds.artOfChording,
  ),
  'paper': Brief(
    outline: 'PAEUP',
    sourceIds: _artOfChordingSources,
    description:
        "Art of Chording, sounds/ay_oy (archived): the brief list gives "
        'PAEUP (and PAEURP) for \'paper\'; PAEUP is used here.',
    wikiForm: 'PAEUP',
    page: SourceIds.artOfChording,
  ),
  'air': Brief(
    outline: 'AEUR',
    sourceIds: _artOfChordingSources,
    description:
        "Art of Chording, sounds/ay_oy (archived): AEUR is the example for "
        "'air'.",
    wikiForm: 'AEUR',
    page: SourceIds.artOfChording,
  ),
};

/// Briefs from the Plover Wiki "Top 100 Words" page.
///
/// Where the wiki notation uses a trailing dash (for example `SKP-`), the
/// clean engine's canonical form drops the dash because the dash only marks
/// the start of the right-hand block. `for` is the one entry whose wiki form
/// (`TP-R`) places a right-hand key after a left-only cluster; the clean
/// engine cannot round-trip that notation, so the generator uses the
/// rule-compatible form `TPOR` and records the adaptation.
const Map<String, Brief> top100Briefs = <String, Brief>{
  'the': Brief(
    outline: '-T',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'the'; right-hand -T.",
    wikiForm: '-T',
    page: SourceIds.top100,
  ),
  'be': Brief(
    outline: '-B',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'be'; right-hand -B.",
    wikiForm: '-B',
    page: SourceIds.top100,
  ),
  'to': Brief(
    outline: 'TO',
    sourceIds: _top100Sources,
    description: "Top 100 spelling brief for 'to'.",
    wikiForm: 'TO',
    page: SourceIds.top100,
  ),
  'of': Brief(
    outline: '-F',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'of'; right-hand -F.",
    wikiForm: '-F',
    page: SourceIds.top100,
  ),
  'and': Brief(
    outline: 'SKP',
    sourceIds: _top100Sources,
    description: "Top 100 left-hand brief for 'and'.",
    wikiForm: 'SKP-',
    page: SourceIds.top100,
  ),
  'a': Brief(
    outline: 'AEU',
    sourceIds: _top100Sources,
    description: "Top 100 tense-A brief for 'a'.",
    wikiForm: 'AEU',
    page: SourceIds.top100,
  ),
  'in': Brief(
    outline: 'TPH',
    sourceIds: _top100Sources,
    description: "Top 100 left-hand N brief for 'in'.",
    wikiForm: 'TPH',
    page: SourceIds.top100,
  ),
  'that': Brief(
    outline: 'THA',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'that'.",
    wikiForm: 'THA',
    page: SourceIds.top100,
  ),
  'have': Brief(
    outline: 'SR',
    sourceIds: _top100Sources,
    description: "Top 100 left-hand V brief for 'have'.",
    wikiForm: 'SR-',
    page: SourceIds.top100,
  ),
  'i': Brief(
    outline: 'EU',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'I'.",
    wikiForm: 'EU',
    page: SourceIds.top100,
  ),
  'it': Brief(
    outline: 'T',
    sourceIds: _top100Sources,
    description: "Top 100 left-hand T brief for 'it'.",
    wikiForm: 'T-',
    page: SourceIds.top100,
  ),
  'not': Brief(
    outline: 'TPHOT',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'not'.",
    wikiForm: 'TPHOT',
    page: SourceIds.top100,
  ),
  'on': Brief(
    outline: 'OPB',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'on'.",
    wikiForm: 'OPB',
    page: SourceIds.top100,
  ),
  'with': Brief(
    outline: 'W',
    sourceIds: _top100Sources,
    description: "Top 100 left-hand W brief for 'with'.",
    wikiForm: 'W-',
    page: SourceIds.top100,
  ),
  'he': Brief(
    outline: 'HE',
    sourceIds: _top100Sources,
    description: "Top 100 spelling form for 'he'.",
    wikiForm: 'HE',
    page: SourceIds.top100,
  ),
  'as': Brief(
    outline: 'AS',
    sourceIds: _top100Sources,
    description: "Top 100 spelling form for 'as'.",
    wikiForm: 'AS',
    page: SourceIds.top100,
  ),
  'you': Brief(
    outline: 'U',
    sourceIds: _top100Sources,
    description: "Top 100 U-key brief for 'you'.",
    wikiForm: 'U',
    page: SourceIds.top100,
  ),
  'do': Brief(
    outline: 'TKO',
    sourceIds: _top100Sources,
    description: "Top 100 spelling form for 'do'.",
    wikiForm: 'TKO',
    page: SourceIds.top100,
  ),
  'at': Brief(
    outline: 'AT',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'at'.",
    wikiForm: 'AT',
    page: SourceIds.top100,
  ),
  'this': Brief(
    outline: 'TH',
    sourceIds: _top100Sources,
    description: "Top 100 TH brief for 'this'.",
    wikiForm: 'TH',
    page: SourceIds.top100,
  ),
  'but': Brief(
    outline: 'PWUT',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'but'.",
    wikiForm: 'PWUT',
    page: SourceIds.top100,
  ),
  'his': Brief(
    outline: 'HEUS',
    sourceIds: _top100Sources,
    description: "Top 100 spelling form for 'his'.",
    wikiForm: 'HEUS',
    page: SourceIds.top100,
  ),
  'by': Brief(
    outline: 'PWEU',
    sourceIds: _top100Sources,
    description: "Top 100 non-phonetic brief for 'by'.",
    wikiForm: 'PWEU',
    page: SourceIds.top100,
  ),
  'from': Brief(
    outline: 'TPR',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'from'; canonical form of TPR-.",
    wikiForm: 'TPR-',
    page: SourceIds.top100,
  ),
  'they': Brief(
    outline: 'THE',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'they'.",
    wikiForm: 'THE',
    page: SourceIds.top100,
  ),
  'we': Brief(
    outline: 'WE',
    sourceIds: _top100Sources,
    description: "Top 100 spelling form for 'we'.",
    wikiForm: 'WE',
    page: SourceIds.top100,
  ),
  'say': Brief(
    outline: 'SAEU',
    sourceIds: _top100Sources,
    description: "Top 100 phonetic form for 'say'.",
    wikiForm: 'SAEU',
    page: SourceIds.top100,
  ),
  'her': Brief(
    outline: 'HER',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'her'.",
    wikiForm: 'HER',
    page: SourceIds.top100,
  ),
  'she': Brief(
    outline: 'SHE',
    sourceIds: _top100Sources,
    description: "Top 100 spelling form for 'she'.",
    wikiForm: 'SHE',
    page: SourceIds.top100,
  ),
  'or': Brief(
    outline: 'OR',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'or'.",
    wikiForm: 'OR',
    page: SourceIds.top100,
  ),
  'an': Brief(
    outline: 'APB',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'an'.",
    wikiForm: 'APB',
    page: SourceIds.top100,
  ),
  'will': Brief(
    outline: 'HR',
    sourceIds: _top100Sources,
    description: "Top 100 left-hand L brief for 'will'.",
    wikiForm: 'HR-',
    page: SourceIds.top100,
  ),
  'my': Brief(
    outline: 'PHEU',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'my'.",
    wikiForm: 'PHEU',
    page: SourceIds.top100,
  ),
  'one': Brief(
    outline: 'WUPB',
    sourceIds: _top100Sources,
    description: "Top 100 phonetic form for 'one'.",
    wikiForm: 'WUPB',
    page: SourceIds.top100,
  ),
  'all': Brief(
    outline: 'AUL',
    sourceIds: _top100Sources,
    description: "Top 100 phonetic form for 'all'.",
    wikiForm: 'AUL',
    page: SourceIds.top100,
  ),
  'would': Brief(
    outline: 'WO',
    sourceIds: _top100Sources,
    description: "Top 100 left-hand brief for 'would'.",
    wikiForm: 'WO',
    page: SourceIds.top100,
  ),
  'there': Brief(
    outline: 'THR',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'there'.",
    wikiForm: 'THR-',
    page: SourceIds.top100,
  ),
  'their': Brief(
    outline: 'THAEUR',
    sourceIds: _top100Sources,
    description: "Top 100 phonetic form for 'their'.",
    wikiForm: 'THAEUR',
    page: SourceIds.top100,
  ),
  'what': Brief(
    outline: 'WHA',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'what'.",
    wikiForm: 'WHA',
    page: SourceIds.top100,
  ),
  'so': Brief(
    outline: 'SO',
    sourceIds: _top100Sources,
    description: "Top 100 spelling form for 'so'.",
    wikiForm: 'SO',
    page: SourceIds.top100,
  ),
  'up': Brief(
    outline: 'UP',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'up'.",
    wikiForm: 'UP',
    page: SourceIds.top100,
  ),
  'out': Brief(
    outline: 'OUT',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'out'.",
    wikiForm: 'OUT',
    page: SourceIds.top100,
  ),
  'if': Brief(
    outline: 'TP',
    sourceIds: _top100Sources,
    description: "Top 100 left-hand F brief for 'if'.",
    wikiForm: 'TP-',
    page: SourceIds.top100,
  ),
  'about': Brief(
    outline: 'PW',
    sourceIds: _top100Sources,
    description: "Top 100 left-hand B brief for 'about'.",
    wikiForm: 'PW-',
    page: SourceIds.top100,
  ),
  'who': Brief(
    outline: 'WHO',
    sourceIds: _top100Sources,
    description: "Top 100 spelling form for 'who'.",
    wikiForm: 'WHO',
    page: SourceIds.top100,
  ),
  'get': Brief(
    outline: 'TKPWET',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'get'.",
    wikiForm: 'TKPWET',
    page: SourceIds.top100,
  ),
  'which': Brief(
    outline: 'WEU',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'which'.",
    wikiForm: 'WEU',
    page: SourceIds.top100,
  ),
  'go': Brief(
    outline: 'TKPWO',
    sourceIds: _top100Sources,
    description: "Top 100 spelling form for 'go'.",
    wikiForm: 'TKPWO',
    page: SourceIds.top100,
  ),
  'me': Brief(
    outline: 'PHE',
    sourceIds: _top100Sources,
    description: "Top 100 spelling form for 'me'.",
    wikiForm: 'PHE',
    page: SourceIds.top100,
  ),
  'when': Brief(
    outline: 'WH',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'when'.",
    wikiForm: 'WH',
    page: SourceIds.top100,
  ),
  'make': Brief(
    outline: 'PHAEUBG',
    sourceIds: _top100Sources,
    description: "Top 100 phonetic form for 'make'.",
    wikiForm: 'PHAEUBG',
    page: SourceIds.top100,
  ),
  'can': Brief(
    outline: 'K',
    sourceIds: _top100Sources,
    description: "Top 100 left-hand K brief for 'can'.",
    wikiForm: 'K-',
    page: SourceIds.top100,
  ),
  'like': Brief(
    outline: 'HRAOEUBG',
    sourceIds: _top100Sources,
    description: "Top 100 phonetic form for 'like'.",
    wikiForm: 'HRAOEUBG',
    page: SourceIds.top100,
  ),
  'time': Brief(
    outline: 'TAOEUPL',
    sourceIds: _top100Sources,
    description: "Top 100 phonetic form for 'time'.",
    wikiForm: 'TAOEUPL',
    page: SourceIds.top100,
  ),
  'no': Brief(
    outline: 'TPHO',
    sourceIds: _top100Sources,
    description: "Top 100 spelling form for 'no'.",
    wikiForm: 'TPHO',
    page: SourceIds.top100,
  ),
  'just': Brief(
    outline: 'SKWRUFT',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'just'.",
    wikiForm: 'SKWRUFT',
    page: SourceIds.top100,
  ),
  'him': Brief(
    outline: 'HEUPL',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'him'.",
    wikiForm: 'HEUPL',
    page: SourceIds.top100,
  ),
  'know': Brief(
    outline: 'TPHOE',
    sourceIds: _top100Sources,
    description: "Top 100 phonetic form for 'know'.",
    wikiForm: 'TPHOE',
    page: SourceIds.top100,
  ),
  'take': Brief(
    outline: 'TAEUBG',
    sourceIds: _top100Sources,
    description: "Top 100 phonetic form for 'take'.",
    wikiForm: 'TAEUBG',
    page: SourceIds.top100,
  ),
  'people': Brief(
    outline: 'PAOEPL',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'people'.",
    wikiForm: 'PAOEPL',
    page: SourceIds.top100,
  ),
  'into': Brief(
    outline: 'TPHAO',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'into'.",
    wikiForm: 'TPHAO',
    page: SourceIds.top100,
  ),
  'year': Brief(
    outline: 'KWRAOER',
    sourceIds: _top100Sources,
    description: "Top 100 phonetic form for 'year'.",
    wikiForm: 'KWRAOER',
    page: SourceIds.top100,
  ),
  'your': Brief(
    outline: 'KWROUR',
    sourceIds: _top100Sources,
    description: "Top 100 spelling form for 'your'.",
    wikiForm: 'KWROUR',
    page: SourceIds.top100,
  ),
  'good': Brief(
    outline: 'TKPWAOD',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'good'.",
    wikiForm: 'TKPWAOD',
    page: SourceIds.top100,
  ),
  'some': Brief(
    outline: 'SOPL',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'some'.",
    wikiForm: 'SOPL',
    page: SourceIds.top100,
  ),
  'could': Brief(
    outline: 'KO',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'could'.",
    wikiForm: 'KO',
    page: SourceIds.top100,
  ),
  'them': Brief(
    outline: 'THEPL',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'them'.",
    wikiForm: 'THEPL',
    page: SourceIds.top100,
  ),
  'see': Brief(
    outline: 'SAOE',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'see'.",
    wikiForm: 'SAOE',
    page: SourceIds.top100,
  ),
  'other': Brief(
    outline: 'OER',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'other'.",
    wikiForm: 'OER',
    page: SourceIds.top100,
  ),
  'than': Brief(
    outline: 'THAPB',
    sourceIds: _top100Sources,
    description: "Top 100 spelling form for 'than'.",
    wikiForm: 'THAPB',
    page: SourceIds.top100,
  ),
  'then': Brief(
    outline: 'THEPB',
    sourceIds: _top100Sources,
    description: "Top 100 spelling form for 'then'.",
    wikiForm: 'THEPB',
    page: SourceIds.top100,
  ),
  'now': Brief(
    outline: 'TPHOU',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'now'.",
    wikiForm: 'TPHOU',
    page: SourceIds.top100,
  ),
  'look': Brief(
    outline: 'HRAOBG',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'look'.",
    wikiForm: 'HRAOBG',
    page: SourceIds.top100,
  ),
  'only': Brief(
    outline: 'OEPBL',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'only'.",
    wikiForm: 'OEPBL',
    page: SourceIds.top100,
  ),
  'come': Brief(
    outline: 'KOPL',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'come'.",
    wikiForm: 'KOPL',
    page: SourceIds.top100,
  ),
  'its': Brief(
    outline: 'EUTS',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'its'.",
    wikiForm: 'EUTS',
    page: SourceIds.top100,
  ),
  'over': Brief(
    outline: 'OEFR',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'over'.",
    wikiForm: 'OEFR',
    page: SourceIds.top100,
  ),
  'think': Brief(
    outline: 'THEU',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'think'.",
    wikiForm: 'THEU',
    page: SourceIds.top100,
  ),
  'also': Brief(
    outline: 'HRS',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'also'; canonical form of HR-S.",
    wikiForm: 'HR-S',
    page: SourceIds.top100,
  ),
  'back': Brief(
    outline: 'PWABG',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'back'.",
    wikiForm: 'PWABG',
    page: SourceIds.top100,
  ),
  'after': Brief(
    outline: 'AF',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'after'.",
    wikiForm: 'AF',
    page: SourceIds.top100,
  ),
  'use': Brief(
    outline: 'AOUZ',
    sourceIds: _top100Sources,
    description:
        "Top 100 form for the verb 'use' (/juːz/); AOUZ keeps the final /z/.",
    wikiForm: 'AOUZ',
    page: SourceIds.top100,
  ),
  'two': Brief(
    outline: 'TWO',
    sourceIds: _top100Sources,
    description: "Top 100 spelling form for 'two'.",
    wikiForm: 'TWO',
    page: SourceIds.top100,
  ),
  'how': Brief(
    outline: 'HOU',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'how'.",
    wikiForm: 'HOU',
    page: SourceIds.top100,
  ),
  'our': Brief(
    outline: 'OUR',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'our'.",
    wikiForm: 'OUR',
    page: SourceIds.top100,
  ),
  'work': Brief(
    outline: 'WORBG',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'work'.",
    wikiForm: 'WORBG',
    page: SourceIds.top100,
  ),
  'first': Brief(
    outline: 'TPEURS',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'first'.",
    wikiForm: 'TPEURS',
    page: SourceIds.top100,
  ),
  'well': Brief(
    outline: 'WEL',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'well'.",
    wikiForm: 'WEL',
    page: SourceIds.top100,
  ),
  'way': Brief(
    outline: 'WAEU',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'way'.",
    wikiForm: 'WAEU',
    page: SourceIds.top100,
  ),
  'even': Brief(
    outline: 'AOEPB',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'even'.",
    wikiForm: 'AOEPB',
    page: SourceIds.top100,
  ),
  'new': Brief(
    outline: 'TPHU',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'new'.",
    wikiForm: 'TPHU',
    page: SourceIds.top100,
  ),
  'want': Brief(
    outline: 'WAPBT',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'want'.",
    wikiForm: 'WAPBT',
    page: SourceIds.top100,
  ),
  'because': Brief(
    outline: 'PWAUS',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'because'.",
    wikiForm: 'PWAUS',
    page: SourceIds.top100,
  ),
  'any': Brief(
    outline: 'TPHEU',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'any'.",
    wikiForm: 'TPHEU',
    page: SourceIds.top100,
  ),
  'these': Brief(
    outline: 'THEZ',
    sourceIds: _top100Sources,
    description: "Top 100 brief for 'these'.",
    wikiForm: 'THEZ',
    page: SourceIds.top100,
  ),
  'give': Brief(
    outline: 'TKPWEUF',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'give'.",
    wikiForm: 'TKPWEUF',
    page: SourceIds.top100,
  ),
  'day': Brief(
    outline: 'TKAEU',
    sourceIds: _top100Sources,
    description: "Top 100 phonetic form for 'day'.",
    wikiForm: 'TKAEU',
    page: SourceIds.top100,
  ),
  'most': Brief(
    outline: 'PHOFT',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'most'.",
    wikiForm: 'PHOFT',
    page: SourceIds.top100,
  ),
  'us': Brief(
    outline: 'US',
    sourceIds: _top100Sources,
    description: "Top 100 form for 'us'.",
    wikiForm: 'US',
    page: SourceIds.top100,
  ),
};

/// Additional briefs authored for Steno Start.
///
/// These are deliberately few. They cover number/function-word forms that
/// differ from the plain phonetic rule and homophone collisions that would
/// otherwise make two words share a chord. Each entry states its reason.
const Map<String, Brief> stenoStartBriefs = <String, Brief>{
  'today': Brief(
    outline: 'TOED',
    sourceIds: <String>[
      SourceIds.top100,
      SourceIds.cmudict,
      SourceIds.wikipedia,
      SourceIds.wordList,
      SourceIds.rules,
    ],
    description:
        "Steno Start compound brief: 'to' (TO) plus the final -D of 'day'.",
  ),
  'four': Brief(
    outline: 'TPAOR',
    sourceIds: <String>[
      SourceIds.cmudict,
      SourceIds.wikipedia,
      SourceIds.wordList,
      SourceIds.rules,
    ],
    description:
        "Steno Start number brief for 'four' (F + AO + R); keeps it distinct "
        "from 'for' TPOR.",
  ),
  'many': Brief(
    outline: 'PHAEPB',
    sourceIds: <String>[
      SourceIds.cmudict,
      SourceIds.rules,
    ],
    description:
        "Steno Start collision brief for 'many'. The plain PHEPB form is the "
        'word men, so the AE vowel keeps many distinct.',
  ),
  'open': Brief(
    outline: 'OEP',
    sourceIds: <String>[
      SourceIds.cmudict,
      SourceIds.wikipedia,
      SourceIds.wordList,
      SourceIds.rules,
    ],
    description:
        "Steno Start collision brief for 'open' (OEP); keeps it distinct from "
        "'own' OEPB.",
  ),
  'city': Brief(
    outline: 'STEUS',
    sourceIds: <String>[
      SourceIds.cmudict,
      SourceIds.wikipedia,
      SourceIds.wordList,
      SourceIds.rules,
    ],
    description:
        "Steno Start collision brief for 'city' (ST + EU + S); keeps it "
        "distinct from 'sit' SEUT.",
  ),
  'hear': Brief(
    outline: 'HAO*ER',
    sourceIds: <String>[
      SourceIds.cmudict,
      SourceIds.wikipedia,
      SourceIds.wordList,
      SourceIds.rules,
    ],
    description:
        "Steno Start homophone brief for 'hear'; 'here' keeps the rule form "
        'HAOER.',
  ),
  'picture': Brief(
    outline: 'P*EUFP',
    sourceIds: _briefIdeaSources,
    description:
        "Brief Ideas -ture pattern: picture as P*EUFP (the page gives this "
        'exact form).',
    wikiForm: 'P*EUFP',
    page: SourceIds.briefIdeas,
  ),
  'road': Brief(
    outline: 'RAOD',
    sourceIds: <String>[
      SourceIds.wikipedia,
      SourceIds.cmudict,
      SourceIds.wordList,
      SourceIds.rules,
    ],
    description:
        "Wikipedia Stenotype chart spelling-disambiguation example: road is "
        'RAOD, contrasting with rode ROED.',
    wikiForm: 'RAOD',
    page: SourceIds.wikipedia,
  ),
};

/// All briefs, with staged precedence:
/// 1. Plover Wiki Top 100,
/// 2. Steno Start-specific briefs,
/// 3. exact Art of Chording examples (they settle any shared word).
///
/// AoC is an allowed source in this lab. A brief that already exists in an
/// earlier layer keeps its outline and gains the AoC citation when the
/// archived page gives the same form.
Map<String, Brief> allBriefs() {
  final Map<String, Brief> merged = <String, Brief>{
    ...top100Briefs,
    ...stenoStartBriefs,
    ...artOfChordingBriefs,
  };

  for (final MapEntry<String, String> example
      in artOfChordingExamples.entries) {
    final Brief? brief = merged[example.key];
    if (brief == null || brief.sourceIds.contains(SourceIds.artOfChording)) {
      continue;
    }
    final String page =
        artOfChordingExamplePages[example.key] ?? 'archived page';
    merged[example.key] = Brief(
      outline: brief.outline,
      sourceIds: <String>[SourceIds.artOfChording, ...brief.sourceIds],
      description: '${brief.description} The Art of Chording archive '
          '($page) gives ${example.value} for "${example.key}".',
      wikiForm: brief.wikiForm,
      page: brief.page,
    );
  }
  return merged;
}
