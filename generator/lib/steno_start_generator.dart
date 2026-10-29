/// Deterministic generator for the Steno Start open 500-word dictionary.
///
/// The generator contains pronunciation rules, a documented briefs layer and
/// deterministic collision handling. It does not embed a complete word ->
/// outline table.
library;

export 'src/briefs.dart';
export 'src/cmudict.dart';
export 'src/generator.dart';
export 'src/rules.dart';
