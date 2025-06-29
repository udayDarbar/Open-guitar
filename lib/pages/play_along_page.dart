// lib/pages/play_along_page.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audio_streamer/audio_streamer.dart';      
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:flutter/services.dart';
import '../models/chord_shape.dart';

class PlayAlongPage extends StatefulWidget {
  @override
  _PlayAlongPageState createState() => _PlayAlongPageState();
}

class _PlayAlongPageState extends State<PlayAlongPage> {
  late final PitchDetector _pitchDetector;
  StreamSubscription<List<double>>? _audioSub;
  List<ChordShape> _chords = [];
  String _detectedChord = 'None';
  String _currentNote = '--';

  @override
  void initState() {
    super.initState();
    _loadChords();
    _pitchDetector = PitchDetector(audioSampleRate: 44100.0, bufferSize: 2048);
    _startListening();
  }

  Future<void> _loadChords() async {
    final raw = await rootBundle.loadString('assets/chord_data.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _chords = map.entries
        .map((e) => ChordShape.fromJson(e.key, e.value))
        .toList();
  }

  void _startListening() async {
    // update sample rate if needed (Android only)
    AudioStreamer().sampleRate = 44100;

    // subscribe to the stream—this “starts” sampling :contentReference[oaicite:1]{index=1}
    _audioSub = AudioStreamer().audioStream.listen((buffer) async {
      final result = await _pitchDetector.getPitchFromFloatBuffer(buffer);
      if (result.pitched) {
        final note = _frequencyToNote(result.pitch);
        setState(() {
          _currentNote = note;
          _detectedChord = _matchChord(note);
        });
      }
    }, onError: (e) {
      print('Audio error: $e');
    });
  }

  String _frequencyToNote(double freq) {
    if (freq <= 0) return '--';
    const names = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B'];
    final midi = (69 + 12 * (log(freq / 440.0) / ln2)).round();
    final name = names[midi % 12];
    final octave = (midi ~/ 12) - 1;
    return '$name$octave';
  }

  String _matchChord(String note) {
    final match = _chords.firstWhere(
      (c) => c.name.toLowerCase().startsWith(note.toLowerCase()),
      orElse: () => ChordShape(name: 'Unknown', frets: [], fingers: []),
    );
    return match.name;
  }

  @override
  void dispose() {
    _audioSub?.cancel();  // this “stops” sampling :contentReference[oaicite:2]{index=2}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Play-Along', style: Theme.of(context).textTheme.headlineMedium),
          SizedBox(height: 20),
          Text('Detected Chord: $_detectedChord',
               style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 20),
          Text('Current Note: $_currentNote',
               style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}