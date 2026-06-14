import '../entities/language.dart';
import '../repositories/character_repository.dart';

class GetLanguages {
  final CharacterRepository _repository;
  const GetLanguages(this._repository);

  Future<List<Language>> call() => _repository.getLanguages();
}
