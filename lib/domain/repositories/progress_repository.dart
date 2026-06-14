import '../entities/progress.dart';

abstract class ProgressRepository {
  Future<Progress?> getProgress(String characterId, String languageId);
  Future<List<Progress>> getAllProgress(String languageId);
  Future<void> saveProgress(Progress progress);
  Future<void> clearProgress(String languageId);
}
