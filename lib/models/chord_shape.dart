class ChordShape {
  final String name;
  final List<int> frets;
  final List<int> fingers;
  ChordShape({required this.name, required this.frets, required this.fingers});
  factory ChordShape.fromJson(String name, Map<String, dynamic> json) {
    return ChordShape(
      name: name,
      frets: List<int>.from(json['frets']),
      fingers: List<int>.from(json['fingers']),
    );
  }
}