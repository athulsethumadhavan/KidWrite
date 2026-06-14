import '../entities/progress.dart';
import '../repositories/progress_repository.dart';

class GetProgress {
  final ProgressRepository _repository;
  const GetProgress(this._repository);

  Future<Progress?> call(String characterId, String languageId) =>
      _repository.getProgress(characterId, languageId);

  Future<List<Progress>> getAll(String languageId) =>
      _repository.getAllProgress(languageId);
}
