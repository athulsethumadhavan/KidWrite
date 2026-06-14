import '../../domain/entities/character.dart';
import '../../domain/entities/language.dart';
import '../../domain/repositories/character_repository.dart';
import '../datasources/character_local_datasource.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  final CharacterLocalDataSource dataSource;
  CharacterRepositoryImpl({required this.dataSource});

  @override
  Future<List<Language>> getLanguages() async =>
      dataSource.getLanguages();

  @override
  Future<List<Character>> getCharacters({
    required String languageId,
    String? category,
  }) async {
    final all = dataSource.getCharacters(languageId);
    if (category == null) return all;
    return all
        .where((c) => c.category.name == category)
        .toList();
  }

  @override
  Future<Character?> getCharacterById(String id) async {
    for (final lang in dataSource.getLanguages()) {
      final chars = dataSource.getCharacters(lang.id);
      try {
        return chars.firstWhere((c) => c.id == id);
      } catch (_) {}
    }
    return null;
  }
}
