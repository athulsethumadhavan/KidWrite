import '../entities/character.dart';
import '../repositories/character_repository.dart';

class GetCharactersParams {
  final String languageId;
  final String? category;
  const GetCharactersParams({required this.languageId, this.category});
}

class GetCharacters {
  final CharacterRepository _repository;
  const GetCharacters(this._repository);

  Future<List<Character>> call(GetCharactersParams params) =>
      _repository.getCharacters(
        languageId: params.languageId,
        category: params.category,
      );
}
