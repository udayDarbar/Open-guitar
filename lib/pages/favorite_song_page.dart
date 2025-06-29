import 'package:flutter/material.dart';

class FavoriteSongPage extends StatefulWidget {
  const FavoriteSongPage({super.key});

  @override
  _FavoriteSongPageState createState() => _FavoriteSongPageState();
}

class _FavoriteSongPageState extends State<FavoriteSongPage> {
  final TextEditingController _controller = TextEditingController();
  List<String> _progression = [];
  int _currentIndex = 0;

  void _startDrill() {
    setState(() {
      _progression = _controller.text.split(',').map((s) => s.trim()).toList();
      _currentIndex = 0;
    });
  }

  void _nextChord() {
    if (_currentIndex < _progression.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentChord = _progression.isEmpty ? '--' : _progression[_currentIndex];
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Favorite Song Drill', style: Theme.of(context).textTheme.headlineMedium),
          TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: 'Enter chords (C, G, Am, F)'),
          ),
          SizedBox(height: 10),
          ElevatedButton(onPressed: _startDrill, child: Text('Start')), 
          SizedBox(height: 20),
          Text('Next Chord:', style: Theme.of(context).textTheme.titleMedium),
          Text(currentChord, style: Theme.of(context).textTheme.displaySmall),
          SizedBox(height: 20),
          ElevatedButton(onPressed: _nextChord, child: Text('Next')),  
        ],
      ),
    );
  }
}
