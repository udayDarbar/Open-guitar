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
  int _adjustLevel = 0; // -4 to +4

  // Open string full names and display labels
  static const List<String> _openStrings = ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'];
  static const List<String> _stringNames = ['E', 'A', 'D', 'G', 'B', 'E'];

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
    // Determine selected string by matching full note
    final selectedIndex = _openStrings.indexOf(_note);

    // Color based on how far (+/-4)
    final accentColor = (_adjustLevel == 0)
        ? Colors.green
        : (_adjustLevel.abs() <= 2)
            ? Colors.orange
            : Colors.red;

    // Text to display: +N or -N
    final adjustText = selectedIndex >= 0
        ? (_adjustLevel > 0 ? '+$_adjustLevel' : '$_adjustLevel')
        : '';

    return Scaffold(
      appBar: AppBar(title: Text('Tuner')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display current note subtly
            if (selectedIndex >= 0)
              Text(
                'Note: $_note',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
            SizedBox(height: 12),

            // Bars and controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                final isSelected = i == selectedIndex;
                return Expanded(
                  child: Column(
                    children: [
                      // Plus/minus text
                      Text(
                        isSelected ? adjustText : '',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? accentColor : Colors.transparent,
                        ),
                      ),
                      SizedBox(height: 8),
                      // String bar
                      Container(
                        width: isSelected ? 6 : 3,
                        height: 200,
                        color: isSelected ? accentColor : Colors.grey.shade300,
                      ),
                      SizedBox(height: 8),
                      // String label
                      Text(
                        _stringNames[i],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? accentColor : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

            SizedBox(height: 24),
            ElevatedButton(
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
          ],
        ),
      ),
    );
  }
}
