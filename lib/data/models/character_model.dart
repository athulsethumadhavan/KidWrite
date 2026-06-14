import '../../domain/entities/character.dart';

class CharacterModel extends Character {
  const CharacterModel({
    required super.id,
    required super.symbol,
    required super.name,
    required super.pronunciation,
    required super.languageId,
    required super.category,
    required super.orderIndex,
  });

  factory CharacterModel.fromMap(Map<String, dynamic> map) {
    return CharacterModel(
      id: map['id'] as String,
      symbol: map['symbol'] as String,
      name: map['name'] as String,
      pronunciation: map['pronunciation'] as String,
      languageId: map['languageId'] as String,
      category: CharacterCategory.values.firstWhere(
            (e) => e.name == map['category'],
        orElse: () => CharacterCategory.lowercase,
      ),
      orderIndex: map['orderIndex'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'symbol': symbol,
    'name': name,
    'pronunciation': pronunciation,
    'languageId': languageId,
    'category': category.name,
    'orderIndex': orderIndex,
  };
}
