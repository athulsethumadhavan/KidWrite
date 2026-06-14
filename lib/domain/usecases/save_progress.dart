import '../entities/progress.dart';
import '../repositories/progress_repository.dart';

class SaveProgress {
  final ProgressRepository _repository;
  const SaveProgress(this._repository);

  Future<void> call(Progress progress) => _repository.saveProgress(progress);
}
