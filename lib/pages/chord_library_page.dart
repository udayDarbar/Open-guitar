import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/chord_shape.dart';
import '../widgets/fretboard_painter.dart';

class ChordLibraryPage extends StatefulWidget {
  @override
  _ChordLibraryPageState createState() => _ChordLibraryPageState();
}

class _ChordLibraryPageState extends State<ChordLibraryPage> {
  List<ChordShape> _chords = [];

  @override
  void initState() {
    super.initState();
    _loadChords();
  }

  Future<void> _loadChords() async {
    final raw = await rootBundle.loadString('assets/chord_data.json');
    final Map<String, dynamic> map = jsonDecode(raw);
    setState(() {
      _chords = map.entries
          .map((e) => ChordShape.fromJson(e.key, e.value))
          .toList();
    });
  }

  void _showChordDetail(ChordShape chord) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        height: 300,
        padding: EdgeInsets.all(16),
        child: CustomPaint(
          size: Size(double.infinity, 200),
          painter: FretboardPainter(chord.frets, chord.fingers),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _chords.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _chords.length,
              itemBuilder: (_, i) {
                final chord = _chords[i];
                return ListTile(
                  title: Text(chord.name),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () => _showChordDetail(chord),
                );
              },
            ),
    );
  }
}