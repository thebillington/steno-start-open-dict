import 'dart:typed_data';

/// A small, dependency-free SHA-256 implementation.
///
/// The provenance layer needs a real SHA-256 digest in three places: the
/// dictionary generator, the verifier tool, and the Flutter test. `package:crypto`
/// is not a dependency of the app (and the app pubspec is deliberately left
/// alone), so the engine ships this compact implementation instead. It follows
/// FIPS 180-4 and is checked against the standard test vectors in
/// `tool/self_test.dart`.
///
/// ```dart
/// import 'package:steno_engine/steno_engine.dart';
/// print(sha256Hex(utf8.encode('abc')));
/// ```
String sha256Hex(List<int> bytes) {
  final Uint8List message = _pad(bytes);
  final List<int> state = <int>[
    0x6a09e667,
    0xbb67ae85,
    0x3c6ef372,
    0xa54ff53a,
    0x510e527f,
    0x9b05688c,
    0x1f83d9ab,
    0x5be0cd19,
  ];
  final List<int> w = List<int>.filled(64, 0);

  for (var offset = 0; offset < message.length; offset += 64) {
    for (var i = 0; i < 16; i++) {
      final int base = offset + i * 4;
      w[i] = (message[base] << 24) |
          (message[base + 1] << 16) |
          (message[base + 2] << 8) |
          message[base + 3];
    }
    for (var i = 16; i < 64; i++) {
      final int s0 =
          _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >>> 3);
      final int s1 =
          _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >>> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & _mask32;
    }

    var a = state[0];
    var b = state[1];
    var c = state[2];
    var d = state[3];
    var e = state[4];
    var f = state[5];
    var g = state[6];
    var h = state[7];

    for (var i = 0; i < 64; i++) {
      final int s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final int ch = (e & f) ^ ((~e & _mask32) & g);
      final int temp1 = (h + s1 + ch + _roundConstants[i] + w[i]) & _mask32;
      final int s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final int maj = (a & b) ^ (a & c) ^ (b & c);
      final int temp2 = (s0 + maj) & _mask32;

      h = g;
      g = f;
      f = e;
      e = (d + temp1) & _mask32;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) & _mask32;
    }

    state[0] = (state[0] + a) & _mask32;
    state[1] = (state[1] + b) & _mask32;
    state[2] = (state[2] + c) & _mask32;
    state[3] = (state[3] + d) & _mask32;
    state[4] = (state[4] + e) & _mask32;
    state[5] = (state[5] + f) & _mask32;
    state[6] = (state[6] + g) & _mask32;
    state[7] = (state[7] + h) & _mask32;
  }

  final StringBuffer buffer = StringBuffer();
  for (final int word in state) {
    buffer.write(word.toRadixString(16).padLeft(8, '0'));
  }
  return buffer.toString();
}

const int _mask32 = 0xffffffff;

int _rotr(int value, int amount) =>
    ((value >>> amount) | (value << (32 - amount))) & _mask32;

Uint8List _pad(List<int> bytes) {
  final int bitLength = bytes.length * 8;
  final int paddedLength = ((bytes.length + 8) ~/ 64 + 1) * 64;
  final Uint8List padded = Uint8List(paddedLength);
  padded.setRange(0, bytes.length, bytes);
  padded[bytes.length] = 0x80;
  // A 64-bit big-endian bit length. Dart's integer literals are wide enough
  // for any realistic input; the high word is written even when it is zero.
  for (var i = 0; i < 8; i++) {
    padded[paddedLength - 1 - i] = (bitLength >>> (8 * i)) & 0xff;
  }
  return padded;
}

const List<int> _roundConstants = <int>[
  0x428a2f98,
  0x71374491,
  0xb5c0fbcf,
  0xe9b5dba5,
  0x3956c25b,
  0x59f111f1,
  0x923f82a4,
  0xab1c5ed5,
  0xd807aa98,
  0x12835b01,
  0x243185be,
  0x550c7dc3,
  0x72be5d74,
  0x80deb1fe,
  0x9bdc06a7,
  0xc19bf174,
  0xe49b69c1,
  0xefbe4786,
  0x0fc19dc6,
  0x240ca1cc,
  0x2de92c6f,
  0x4a7484aa,
  0x5cb0a9dc,
  0x76f988da,
  0x983e5152,
  0xa831c66d,
  0xb00327c8,
  0xbf597fc7,
  0xc6e00bf3,
  0xd5a79147,
  0x06ca6351,
  0x14292967,
  0x27b70a85,
  0x2e1b2138,
  0x4d2c6dfc,
  0x53380d13,
  0x650a7354,
  0x766a0abb,
  0x81c2c92e,
  0x92722c85,
  0xa2bfe8a1,
  0xa81a664b,
  0xc24b8b70,
  0xc76c51a3,
  0xd192e819,
  0xd6990624,
  0xf40e3585,
  0x106aa070,
  0x19a4c116,
  0x1e376c08,
  0x2748774c,
  0x34b0bcb5,
  0x391c0cb3,
  0x4ed8aa4a,
  0x5b9cca4f,
  0x682e6ff3,
  0x748f82ee,
  0x78a5636f,
  0x84c87814,
  0x8cc70208,
  0x90befffa,
  0xa4506ceb,
  0xbef9a3f7,
  0xc67178f2,
];
