import '../entities/character.dart';
import '../entities/language.dart';

abstract class CharacterRepository {
  /// Returns all supported languages.
  Future<List<Language>> getLanguages();

  /// Returns characters for [languageId], optionally filtered by [category].
  Future<List<Character>> getCharacters({
    required String languageId,
    String? category,
  });

  /// Returns a single character by its [id].
  Future<Character?> getCharacterById(String id);
}
