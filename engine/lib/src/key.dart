/// The keyboard side (or special group) a steno key belongs to.
enum KeySide { left, vowel, star, right }

/// A single physical key on the 22-key steno keyboard.
///
/// [id] is the position in steno order (0-based). The steno order is:
///
///     S- T- K- P- W- H- R- A O * -E -U -F -R -P -B -L -G -T -S -D -Z
class StenoKey {
  const StenoKey(this.id, this.letter, this.side);

  /// Position in steno order, 0..21.
  final int id;

  /// The single character written for this key (`A`, `*`, `T`, ...).
  final String letter;

  /// Which group of the keyboard the key belongs to.
  final KeySide side;

  bool get isLeftHand => side == KeySide.left;

  bool get isVowel => side == KeySide.vowel;

  bool get isStar => side == KeySide.star;

  bool get isRightHand => side == KeySide.right;

  /// The key as it appears in the steno-order listing, e.g. `S-`, `A`, `*`, `-T`.
  ///
  /// Note that this is *not* how strokes are formatted: strokes only use a
  /// leading `-` when the first selected key is right-hand.
  String get label => switch (side) {
        KeySide.left => '$letter-',
        KeySide.right => '-$letter',
        KeySide.vowel || KeySide.star => letter,
      };

  @override
  String toString() => label;
}

/// The 22 keys in steno order. Index in this list == [StenoKey.id].
const List<StenoKey> stenoKeys = <StenoKey>[
  StenoKey(0, 'S', KeySide.left),
  StenoKey(1, 'T', KeySide.left),
  StenoKey(2, 'K', KeySide.left),
  StenoKey(3, 'P', KeySide.left),
  StenoKey(4, 'W', KeySide.left),
  StenoKey(5, 'H', KeySide.left),
  StenoKey(6, 'R', KeySide.left),
  StenoKey(7, 'A', KeySide.vowel),
  StenoKey(8, 'O', KeySide.vowel),
  StenoKey(9, '*', KeySide.star),
  StenoKey(10, 'E', KeySide.vowel),
  StenoKey(11, 'U', KeySide.vowel),
  StenoKey(12, 'F', KeySide.right),
  StenoKey(13, 'R', KeySide.right),
  StenoKey(14, 'P', KeySide.right),
  StenoKey(15, 'B', KeySide.right),
  StenoKey(16, 'L', KeySide.right),
  StenoKey(17, 'G', KeySide.right),
  StenoKey(18, 'T', KeySide.right),
  StenoKey(19, 'S', KeySide.right),
  StenoKey(20, 'D', KeySide.right),
  StenoKey(21, 'Z', KeySide.right),
];

/// Number of keys on the keyboard.
const int stenoKeyCount = 22;

/// Index of the first right-hand key (`-F`). Everything before it is left,
/// vowel, or star territory.
const int firstRightHandIndex = 12;

/// The key at [id], validated.
StenoKey keyAt(int id) {
  RangeError.checkValueInInterval(id, 0, stenoKeyCount - 1, 'id');
  return stenoKeys[id];
}

/// All keys on [side], in steno order.
Iterable<StenoKey> keysOnSide(KeySide side) =>
    stenoKeys.where((StenoKey key) => key.side == side);

/// All keys whose letter is [letter], in steno order (left before right).
Iterable<StenoKey> keysForLetter(String letter) =>
    stenoKeys.where((StenoKey key) => key.letter == letter);
