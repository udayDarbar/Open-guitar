import 'package:flutter/material.dart';
import 'pages/tuner_page.dart';
import 'pages/chord_library_page.dart';
import 'pages/play_along_page.dart';
import 'pages/favorite_song_page.dart';

void main() => runApp(ChordDetectApp());

class ChordDetectApp extends StatelessWidget {
  const ChordDetectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Acoustic Chord Detector',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _pages = [
    TunerPage(),
    ChordLibraryPage(),
    PlayAlongPage(),
    FavoriteSongPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Acoustic Chord Detector'),
        centerTitle: true,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'Tuner'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Chords'),
          BottomNavigationBarItem(icon: Icon(Icons.play_arrow), label: 'Play-Along'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorite'),
        ],
      ),
    );
  }
}
