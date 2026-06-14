import 'package:equatable/equatable.dart';

enum CharacterCategory { vowel, consonant, number, uppercase, lowercase }

class Character extends Equatable {
  final String id;
  final String symbol;       // Actual Unicode character, e.g. 'A', 'അ'
  final String name;         // English name, e.g. 'Letter A', 'Vowel A'
  final String pronunciation; // How it sounds, e.g. 'ay', 'ah'
  final String languageId;
  final CharacterCategory category;
  final int orderIndex;

  const Character({
    required this.id,
    required this.symbol,
    required this.name,
    required this.pronunciation,
    required this.languageId,
    required this.category,
    required this.orderIndex,
  });

  @override
  List<Object?> get props => [id];
}
