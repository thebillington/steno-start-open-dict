import 'key.dart';

/// A single steno chord: an unordered *set* of key ids.
///
/// Strokes are value objects. Equality and [hashCode] are based on
/// [signature] (the sorted key ids joined with `|`), so the same chord written
/// in any notation compares equal.
///
/// ```dart
/// final stroke = Stroke.parse('KAT');
/// stroke.signature; // '2|7|18'
/// stroke.format();  // 'KAT'
/// stroke.describe(); // 'left K · vowel A · right T'
/// ```
class Stroke {
  Stroke._(this._ids) : signature = _ids.join('|');

  /// Creates a stroke from arbitrary key ids. Duplicates are removed and the
  /// ids are sorted into steno order.
  ///
  /// Throws a [RangeError] if any id is outside `0..21`.
  factory Stroke.fromKeyIds(Iterable<int> keyIds) {
    final Set<int> unique = <int>{};
    for (final int id in keyIds) {
      RangeError.checkValueInInterval(id, 0, stenoKeyCount - 1, 'keyId');
      unique.add(id);
    }
    final List<int> sorted = unique.toList()..sort();
    return Stroke._(List<int>.unmodifiable(sorted));
  }

  /// Parses a stroke written in steno notation.
  ///
  /// Parsing is case-insensitive and ignores surrounding whitespace.
  /// Throws a [FormatException] if the text is not a valid stroke.
  static Stroke parse(String stroke) {
    final String text = stroke.trim().toUpperCase();
    if (text.isEmpty) {
      throw FormatException(
        'Empty stroke: a stroke must name at least one key.',
        stroke,
      );
    }

    final Set<int> ids = <int>{};
    var from = 0;
    var sawDash = false;

    for (var i = 0; i < text.length; i++) {
      final String char = text[i];

      if (char == '-') {
        if (sawDash) {
          throw FormatException(
            'Stroke "$stroke" contains more than one "-".',
            stroke,
          );
        }
        if (i == text.length - 1) {
          throw FormatException(
            'Stroke "$stroke" ends with "-": a dash must be followed by a '
            'right-hand key.',
            stroke,
          );
        }
        if (from > firstRightHandIndex) {
          throw FormatException(
            'Stroke "$stroke" puts "-" after a right-hand key. The dash only '
            'marks the start of the right-hand keys.',
            stroke,
          );
        }
        sawDash = true;
        from = firstRightHandIndex;
        continue;
      }

      final int? id = _findKeyFrom(char, from);
      if (id == null) {
        throw FormatException(
          'Cannot parse stroke "$stroke": key "$char" is not available after '
          '${i == 0 ? 'the start' : '"${text[i - 1]}"'} in steno order '
          '(${_orderHint(char)}).',
          stroke,
        );
      }
      ids.add(id);
      from = id + 1;
    }

    final List<int> sorted = ids.toList()..sort();
    return Stroke._(List<int>.unmodifiable(sorted));
  }

  /// Like [Stroke.parse], but returns `null` instead of throwing.
  static Stroke? tryParse(String stroke) {
    try {
      return Stroke.parse(stroke);
    } on FormatException {
      return null;
    }
  }

  /// Sorted key ids, in steno order.
  final List<int> _ids;

  /// Canonical, notation-independent identity: sorted key ids joined by `|`.
  ///
  /// For `KAT` this is `2|7|18`.
  final String signature;

  /// The key ids of this stroke, in steno order.
  List<int> get keyIds => _ids;

  /// The [StenoKey]s of this stroke, in steno order.
  Iterable<StenoKey> get keys => _ids.map(keyAt);

  /// Whether this stroke presses no keys. Only possible via [Stroke.fromKeyIds].
  bool get isEmpty => _ids.isEmpty;

  /// Whether [id] is part of this stroke.
  bool containsKeyId(int id) => _ids.contains(id);

  /// Whether [key] is part of this stroke.
  bool containsKey(StenoKey key) => containsKeyId(key.id);

  /// Formats the stroke canonically: letters in steno order, with a leading
  /// `-` only when the first selected key is right-hand.
  ///
  /// The result always parses back to the same set of keys.
  String format() {
    final StringBuffer buffer = StringBuffer();
    if (_ids.isNotEmpty && keyAt(_ids.first).isRightHand) {
      buffer.write('-');
    }
    for (final int id in _ids) {
      buffer.write(keyAt(id).letter);
    }
    return buffer.toString();
  }

  /// Human-readable grouping, e.g. `left K · vowel A · right T`.
  String describe() => describeKeys(_ids);

  /// Whether [other] presses exactly the same keys.
  bool sameKeysAs(Stroke other) => signature == other.signature;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Stroke && signature == other.signature;

  @override
  int get hashCode => signature.hashCode;

  @override
  String toString() => format();
}

int? _findKeyFrom(String letter, int from) {
  for (var id = from; id < stenoKeyCount; id++) {
    if (stenoKeys[id].letter == letter) {
      return id;
    }
  }
  return null;
}

String _orderHint(String letter) {
  final List<String> labels =
      keysForLetter(letter).map((StenoKey key) => key.label).toList();
  if (labels.isEmpty) {
    return '"$letter" is not a steno key; valid keys are '
        '${stenoKeys.map((StenoKey key) => key.letter).toSet().join()}';
  }
  return 'the remaining "$letter" key(s) are ${labels.join(', ')}';
}

/// Describes a set of key ids by group, in this order:
/// left, vowel(s), asterisk, right.
///
/// Groups are separated by ` · ` and only present groups are shown:
///
/// * `{K, A, T}` -> `left K · vowel A · right T`
/// * `{A, E, U}` -> `vowels AEU`
/// * `{*}` -> `asterisk`
/// * `{T, K, P, W, O}` -> `left TKPW · vowel O`
/// * `{}` -> `empty`
String describeKeys(Iterable<int> keyIds) {
  final List<int> ids = keyIds.toSet().toList()..sort();
  if (ids.isEmpty) {
    return 'empty';
  }

  final List<String> left = <String>[];
  final List<String> vowels = <String>[];
  var hasStar = false;
  final List<String> right = <String>[];

  for (final int id in ids) {
    final StenoKey key = keyAt(id);
    switch (key.side) {
      case KeySide.left:
        left.add(key.letter);
      case KeySide.vowel:
        vowels.add(key.letter);
      case KeySide.star:
        hasStar = true;
      case KeySide.right:
        right.add(key.letter);
    }
  }

  final List<String> parts = <String>[];
  if (left.isNotEmpty) {
    parts.add('left ${left.join()}');
  }
  if (vowels.isNotEmpty) {
    parts.add('${vowels.length == 1 ? 'vowel' : 'vowels'} ${vowels.join()}');
  }
  if (hasStar) {
    parts.add('asterisk');
  }
  if (right.isNotEmpty) {
    parts.add('right ${right.join()}');
  }
  return parts.join(' · ');
}

/// Parses [stroke] and describes it. Throws a [FormatException] if invalid.
String describeStroke(String stroke) => Stroke.parse(stroke).describe();
