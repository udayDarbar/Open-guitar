// lib/pages/tuner_page.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audio_streamer/audio_streamer.dart';      // audio_streamer: ^4.2.0 :contentReference[oaicite:3]{index=3}
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:permission_handler/permission_handler.dart';

class TunerPage extends StatefulWidget {
  @override
  _TunerPageState createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage> {
  late final PitchDetector _pitchDetector;
  StreamSubscription<List<double>>? _audioSub;

  String _note = '--';
  int _adjustLevel = 0; // from -4 to +4

  // Standard tuning MIDI note names
  static const List<String> _openStrings = ['D2', 'A2', 'E3', 'G3', 'B3', 'E4'];

  @override
  void initState() {
    super.initState();
    _pitchDetector = PitchDetector(audioSampleRate: 44100.0, bufferSize: 2048);
    _requestPermissionAndStart();
  }

  Future<void> _requestPermissionAndStart() async {
    if (await Permission.microphone.request().isGranted) {
      _startTuner();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microphone permission is required to tune.')),
      );
    }
  }

  void _startTuner() {
    AudioStreamer().sampleRate = 44100;
    _audioSub = AudioStreamer().audioStream.listen(
      _processBuffer,
      onError: (e) => print('Audio error: $e'),
    );
  }

  void _processBuffer(List<double> buffer) async {
    if (buffer.isEmpty) return;
    final result = await _pitchDetector.getPitchFromFloatBuffer(buffer);
    final freq = result.pitched ? result.pitch : 0.0;
    if (freq > 0) {
      final midiFloat = 69 + 12 * (log(freq / 440.0) / ln2);
      final midiInt = midiFloat.round();
      final offset = (midiFloat - midiInt) * 100;
      final level = (offset / 5).round().clamp(-4, 4);

      setState(() {
        _adjustLevel = level;
        _note = _midiToNote(midiInt);
      });
    }
  }

  String _midiToNote(int midi) {
    const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final name = notes[midi % 12];
    final octave = (midi ~/ 12) - 1;
    return '$name$octave';
  }

  @override
  void dispose() {
    _audioSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Color based on tuning offset
    final accentColor = (_adjustLevel == 0)
        ? Colors.green
        : (_adjustLevel.abs() <= 2)
            ? Colors.orange
            : Colors.red;

    return Scaffold(
      appBar: AppBar(title: Text('Tuner')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Pitch line
          CustomPaint(
            painter: PitchLinePainter(_adjustLevel),
            child: Container(width: 60, height: 300),
          ),

          // Tuning offset and note
          Positioned(
            top: 100,
            child: Column(
              children: [
                if (_note != '--') ...[
                  Text(
                    _adjustLevel > 0 ? '+$_adjustLevel' : '$_adjustLevel',
                    style: TextStyle(fontSize: 32, color: accentColor),
                  ),
                  Icon(Icons.arrow_drop_down, size: 32, color: accentColor),
                  Text(
                    _note,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightBlueAccent,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(1, 1))],
                    ),
                  ),
                ]
              ],
            ),
          ),

          // Headstock + tuning buttons
          Align(
            alignment: Alignment.bottomCenter,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/headstock.png',
                  height: MediaQuery.of(context).size.height * 0.75,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),

                // Left side: E2, A2, D3
                Positioned(
                  left: 20,
                  top: 120,
                  child: Column(
                    children: List.generate(3, (i) {
                      final noteLabel = _openStrings[i];
                      return TunerButton(
                        label: noteLabel.substring(0, 1),
                        selected: _note == noteLabel,
                      );
                    }),
                  ),
                ),

                // Right side: G3, B3, E4
                Positioned(
                  right: 20,
                  top: 120,
                  child: Column(
                    children: List.generate(3, (i) {
                      final noteLabel = _openStrings[i + 3];
                      return TunerButton(
                        label: noteLabel.substring(0, 1),
                        selected: _note == noteLabel,
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // Start/Stop button
          Positioned(
            bottom: 20,
            child: ElevatedButton(
              onPressed: () {
                if (_audioSub == null) {
                  _startTuner();
                } else {
                  _audioSub?.cancel();
                  _audioSub = null;
                  setState(() {
                    _adjustLevel = 0;
                    _note = '--';
                  });
                }
              },
              child: Text(_audioSub == null ? 'Start Tuning' : 'Stop Tuning'),
            ),
          ),
        ],
      ),
    );
  }
}

class PitchLinePainter extends CustomPainter {
  final int level;
  PitchLinePainter(this.level);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = level == 0 ? Colors.green : Colors.grey
      ..strokeWidth = 3;

    final centerX = size.width / 2;
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), paint);
  }

  @override
  bool shouldRepaint(PitchLinePainter old) => old.level != level;
}

class TunerButton extends StatelessWidget {
  final String label;
  final bool selected;

  const TunerButton({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? Colors.lightBlueAccent : Colors.grey.shade400,
          width: selected ? 3.0 : 1.0,
        ),
      ),
      padding: EdgeInsets.all(12),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: selected ? Colors.lightBlueAccent : Colors.grey.shade600,
        ),
      ),
    );
  }
}