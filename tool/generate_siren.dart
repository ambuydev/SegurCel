import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  const sampleRate = 44100;
  const durationSeconds = 4.0;
  final numSamples = (sampleRate * durationSeconds).toInt();
  final numBytes = numSamples * 2; // 16-bit mono

  final wavData = ByteData(44 + numBytes);

  // RIFF Header
  wavData.setUint8(0, 0x52); // 'R'
  wavData.setUint8(1, 0x49); // 'I'
  wavData.setUint8(2, 0x46); // 'F'
  wavData.setUint8(3, 0x46); // 'F'
  wavData.setUint32(4, 36 + numBytes, Endian.little);
  wavData.setUint8(8, 0x57);  // 'W'
  wavData.setUint8(9, 0x41);  // 'A'
  wavData.setUint8(10, 0x56); // 'V'
  wavData.setUint8(11, 0x45); // 'E'

  // fmt Subchunk
  wavData.setUint8(12, 0x66); // 'f'
  wavData.setUint8(13, 0x6D); // 'm'
  wavData.setUint8(14, 0x74); // 't'
  wavData.setUint8(15, 0x20); // ' '
  wavData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
  wavData.setUint16(20, 1, Endian.little);  // AudioFormat (1 for PCM)
  wavData.setUint16(22, 1, Endian.little);  // NumChannels (1 for Mono)
  wavData.setUint32(24, sampleRate, Endian.little);
  wavData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
  wavData.setUint16(32, 2, Endian.little);  // BlockAlign
  wavData.setUint16(34, 16, Endian.little); // BitsPerSample

  // data Subchunk
  wavData.setUint8(36, 0x64); // 'd'
  wavData.setUint8(37, 0x61); // 'a'
  wavData.setUint8(38, 0x74); // 't'
  wavData.setUint8(39, 0x61); // 'a'
  wavData.setUint32(40, numBytes, Endian.little);

  // Generator: Sweep between 800 Hz and 1500 Hz
  double phase = 0.0;
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    // Frequency sweeps smoothly up and down
    final currentFreq = 800.0 + 700.0 * (0.5 + 0.5 * sin(2 * pi * 1.5 * t));
    phase += 2 * pi * currentFreq / sampleRate;

    // Amplitude: 30,000 (~92% of max 32,767 for loud volume without distortion)
    final sampleVal = (30000.0 * sin(phase)).clamp(-32768.0, 32767.0).toInt();
    wavData.setInt16(44 + (i * 2), sampleVal, Endian.little);
  }

  final dir = Directory('android/app/src/main/res/raw');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final file = File('android/app/src/main/res/raw/siren_police.wav');
  file.writeAsBytesSync(wavData.buffer.asUint8List());
  print('Sirena policial WAV generada con exito en: ${file.path}');
}
