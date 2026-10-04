// Synthesises every sound of the game into assets/audio/*.wav.
//
//   dart run tool/generate_sounds.dart
//
// Everything is generated from maths (sines, noise, plucked strings), so the
// project ships no third-party audio and needs no download.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 22050;
final Random _rng = Random(2026);

typedef Samples = Float64List;

Samples silence(double seconds) => Float64List((seconds * sampleRate).round());

void mix(Samples target, Samples source, {double at = 0, double gain = 1}) {
  final offset = (at * sampleRate).round();
  for (var i = 0; i < source.length && offset + i < target.length; i++) {
    target[offset + i] += source[i] * gain;
  }
}

/// Decaying sine with an optional pitch drop (drums, thuds).
Samples tone(
  double freq,
  double seconds, {
  double decay = 8,
  double drop = 0,
  double attack = 0.003,
}) {
  final out = silence(seconds);
  var phase = 0.0;
  for (var i = 0; i < out.length; i++) {
    final t = i / sampleRate;
    final f = freq * (1 - drop * min(1.0, t / seconds));
    phase += 2 * pi * f / sampleRate;
    final env = min(1.0, t / attack) * exp(-decay * t);
    out[i] = sin(phase) * env;
  }
  return out;
}

/// Noise burst through a one-pole low-pass (clicks, taps, whooshes).
Samples noise(double seconds, {double decay = 30, double cutoff = 0.5}) {
  final out = silence(seconds);
  var last = 0.0;
  for (var i = 0; i < out.length; i++) {
    final t = i / sampleRate;
    last += cutoff * ((_rng.nextDouble() * 2 - 1) - last);
    out[i] = last * exp(-decay * t);
  }
  return out;
}

/// Karplus-Strong plucked string: a warm, oud-like note.
Samples pluck(double freq, double seconds, {double damping = 0.996}) {
  final out = silence(seconds);
  final period = (sampleRate / freq).round();
  final buffer = Float64List(period);
  for (var i = 0; i < period; i++) {
    buffer[i] = _rng.nextDouble() * 2 - 1;
  }
  // Soften the excitation so the attack is not harsh.
  for (var pass = 0; pass < 2; pass++) {
    for (var i = 1; i < period; i++) {
      buffer[i] = (buffer[i] + buffer[i - 1]) / 2;
    }
  }
  var index = 0;
  for (var i = 0; i < out.length; i++) {
    final next = (index + 1) % period;
    out[i] = buffer[index];
    buffer[index] = damping * 0.5 * (buffer[index] + buffer[next]);
    index = next;
  }
  return out;
}

/// Soft bell: fundamental plus two partials.
Samples bell(double freq, double seconds, {double decay = 5}) {
  final out = silence(seconds);
  mix(out, tone(freq, seconds, decay: decay));
  mix(out, tone(freq * 2.01, seconds, decay: decay * 1.6), gain: 0.35);
  mix(out, tone(freq * 3.02, seconds, decay: decay * 2.4), gain: 0.15);
  return out;
}

/// Wooden "thock" of a piece landing on the board.
Samples thock({double pitch = 190, double gain = 1}) {
  final out = silence(0.16);
  mix(out, tone(pitch, 0.16, decay: 38, drop: 0.35), gain: 0.9 * gain);
  mix(out, tone(pitch * 2.6, 0.08, decay: 70), gain: 0.25 * gain);
  mix(out, noise(0.05, decay: 110, cutoff: 0.6), gain: 0.5 * gain);
  return out;
}

/// Darbuka strokes: "dum" (bass) and "tek" (rim).
Samples dum() {
  final out = silence(0.35);
  mix(out, tone(95, 0.35, decay: 11, drop: 0.3), gain: 1.0);
  mix(out, noise(0.03, decay: 150, cutoff: 0.3), gain: 0.4);
  return out;
}

Samples tek() {
  final out = silence(0.12);
  mix(out, tone(430, 0.12, decay: 45), gain: 0.5);
  mix(out, noise(0.06, decay: 90, cutoff: 0.8), gain: 0.6);
  return out;
}

Samples whoosh(double seconds) {
  final out = silence(seconds);
  var last = 0.0;
  for (var i = 0; i < out.length; i++) {
    final t = i / out.length;
    // The filter opens while the curtain slides, then closes.
    final cutoff = 0.02 + 0.25 * sin(pi * t);
    last += cutoff * ((_rng.nextDouble() * 2 - 1) - last);
    out[i] = last * pow(sin(pi * t), 1.5);
  }
  return out;
}

Float64List normalise(Samples samples, double peak) {
  var top = 1e-9;
  for (final s in samples) {
    top = max(top, s.abs());
  }
  final out = Float64List(samples.length);
  for (var i = 0; i < samples.length; i++) {
    out[i] = samples[i] / top * peak;
  }
  // Short fade-out to avoid a click at the end.
  final fade = min(samples.length, (0.012 * sampleRate).round());
  for (var i = 0; i < fade; i++) {
    out[out.length - 1 - i] *= i / fade;
  }
  return out;
}

void writeWav(String name, Samples samples, {double peak = 0.8}) {
  final data = normalise(samples, peak);
  final bytes = ByteData(44 + data.length * 2);
  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      bytes.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + data.length * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little); // PCM
  bytes.setUint16(22, 1, Endian.little); // mono
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bytes.setUint32(40, data.length * 2, Endian.little);
  for (var i = 0; i < data.length; i++) {
    bytes.setInt16(44 + i * 2, (data[i] * 32767).round(), Endian.little);
  }
  final file = File('assets/audio/$name.wav')..createSync(recursive: true);
  file.writeAsBytesSync(bytes.buffer.asUint8List());
  stdout.writeln('  $name.wav  ${(file.lengthSync() / 1024).round()} KB');
}

// D hijaz: D Eb F# G A Bb C D — the colour of a lot of Tunisian music.
const double _d3 = 146.83;
double _semitone(int n) => _d3 * pow(2, n / 12).toDouble();
final List<double> hijaz = [
  for (final n in [0, 1, 4, 5, 7, 8, 10, 12, 13, 16, 17, 19]) _semitone(n),
];

Samples music() {
  const beat = 0.42;
  const bars = 8;
  final total = beat * 8 * bars;
  final out = silence(total + 0.01);
  // Scale degrees per half-beat; -1 is a rest.
  const phrases = [
    [7, -1, 8, 9, 7, -1, 6, 5, 4, -1, 5, 6, 4, -1, -1, -1],
    [4, -1, 5, 6, 7, -1, 8, 7, 6, -1, 5, 4, 2, -1, -1, -1],
    [7, -1, 9, 10, 11, -1, 10, 9, 8, -1, 9, 7, 6, -1, -1, -1],
    [6, -1, 5, 4, 2, -1, 1, 2, 0, -1, -1, -1, 0, -1, -1, -1],
  ];
  for (var bar = 0; bar < bars; bar++) {
    final phrase = phrases[bar % phrases.length];
    final start = bar * beat * 8;
    for (var step = 0; step < phrase.length; step++) {
      final degree = phrase[step];
      if (degree < 0) continue;
      mix(
        out,
        pluck(hijaz[degree] * 2, 1.4),
        at: start + step * beat / 2,
        gain: 0.55,
      );
    }
    // Drone on the tonic and a quiet "dum … tek tek" pulse underneath.
    mix(out, pluck(_d3 / 2, 3.2, damping: 0.998), at: start, gain: 0.5);
    mix(out, dum(), at: start, gain: 0.22);
    mix(out, tek(), at: start + beat * 3, gain: 0.10);
    mix(out, dum(), at: start + beat * 4, gain: 0.16);
    mix(out, tek(), at: start + beat * 6, gain: 0.10);
    mix(out, tek(), at: start + beat * 7, gain: 0.08);
  }
  // Wrap the tail onto the beginning so the loop is seamless.
  final loop = silence(total);
  for (var i = 0; i < out.length; i++) {
    loop[i % loop.length] += out[i];
  }
  return loop;
}

void main() {
  stdout.writeln('Generating sounds into assets/audio/');

  writeWav('move', thock(), peak: 0.75);
  writeWav('place', thock(pitch: 240, gain: 0.8), peak: 0.55);

  final capture = silence(0.26);
  mix(capture, thock(pitch: 150));
  mix(capture, thock(pitch: 230), at: 0.075, gain: 0.8);
  writeWav('capture', capture, peak: 0.85);

  final check = silence(0.5);
  mix(check, bell(_semitone(19), 0.25, decay: 9));
  mix(check, bell(_semitone(24), 0.36, decay: 7), at: 0.12);
  writeWav('check', check, peak: 0.6);

  final promotion = silence(0.75);
  for (final (i, n) in [12, 16, 19, 24].indexed) {
    mix(promotion, bell(_semitone(n), 0.5, decay: 6), at: i * 0.08);
  }
  writeWav('promotion', promotion, peak: 0.6);

  final start = silence(0.95);
  mix(start, dum());
  mix(start, tek(), at: 0.22, gain: 0.8);
  mix(start, tek(), at: 0.36, gain: 0.8);
  mix(start, dum(), at: 0.52);
  writeWav('gameStart', start, peak: 0.8);

  final win = silence(1.6);
  for (final (i, n) in [12, 16, 19, 24, 28].indexed) {
    mix(win, pluck(_semitone(n), 1.2), at: i * 0.11, gain: 0.8);
    mix(win, bell(_semitone(n), 0.9, decay: 4), at: i * 0.11, gain: 0.5);
  }
  writeWav('win', win, peak: 0.7);

  final lose = silence(1.5);
  for (final (i, n) in [12, 10, 8, 7, 5].indexed) {
    mix(lose, pluck(_semitone(n), 1.2), at: i * 0.16, gain: 0.8);
  }
  writeWav('lose', lose, peak: 0.6);

  final draw = silence(1.0);
  mix(draw, pluck(_semitone(12), 0.9));
  mix(draw, pluck(_semitone(7), 0.9), at: 0.18);
  mix(draw, pluck(_semitone(12), 0.8), at: 0.36);
  writeWav('draw', draw, peak: 0.6);

  final illegal = silence(0.2);
  mix(illegal, tone(110, 0.2, decay: 22), gain: 0.9);
  mix(illegal, tone(104, 0.2, decay: 22), gain: 0.7);
  writeWav('illegal', illegal, peak: 0.45);

  writeWav('tick', tek(), peak: 0.6);

  final curtain = silence(1.8);
  mix(curtain, whoosh(1.7), gain: 1.0);
  writeWav('curtain', curtain, peak: 0.7);

  final reveal = silence(1.9);
  mix(reveal, dum(), gain: 1.0);
  mix(reveal, tek(), at: 0.16, gain: 0.7);
  mix(reveal, dum(), at: 0.3, gain: 1.0);
  for (final (i, n) in [0, 7, 12, 16].indexed) {
    mix(reveal, pluck(_semitone(n + 12), 1.4), at: 0.45 + i * 0.03, gain: 0.6);
    mix(
      reveal,
      bell(_semitone(n + 12), 1.2, decay: 3.5),
      at: 0.45 + i * 0.03,
      gain: 0.3,
    );
  }
  writeWav('reveal', reveal, peak: 0.8);

  writeWav('music', music(), peak: 0.6);
  stdout.writeln('Done.');
}
