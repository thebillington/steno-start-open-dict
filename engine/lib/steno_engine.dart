/// A small, dependency-free clean-room steno (stenotype) chord engine.
///
/// The model is deliberately simple: a stroke is a *set* of the 22 keys,
///
///     S- T- K- P- W- H- R- A O * -E -U -F -R -P -B -L -G -T -S -D -Z
///
/// written in steno order. Parsing walks that order from the left, resolving
/// each letter to the next matching key, with `-` jumping to the right-hand
/// block. A [Stroke]'s [Stroke.signature] (sorted key ids joined with `|`) is
/// its notation-independent identity, and [StenoDictionary] indexes words by
/// it.
///
/// ```dart
/// import 'package:steno_engine/steno_engine.dart';
///
/// final stroke = Stroke.parse('KAT');
/// print(stroke.signature); // 2|7|18
/// print(stroke.describe()); // left K · vowel A · right T
/// ```
library;

export 'src/dictionary.dart';
export 'src/key.dart';
export 'src/sha256.dart';
export 'src/stroke.dart';
