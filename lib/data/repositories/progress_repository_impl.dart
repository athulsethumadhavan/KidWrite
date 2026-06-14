import '../../domain/entities/progress.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_local_datasource.dart';
import '../models/progress_model.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final ProgressLocalDataSource dataSource;
  ProgressRepositoryImpl({required this.dataSource});

  @override
  Future<Progress?> getProgress(
      String characterId, String languageId) async =>
      dataSource.getProgress(characterId, languageId);

  @override
  Future<List<Progress>> getAllProgress(String languageId) async =>
      dataSource.getAllProgress(languageId);

  @override
  Future<void> saveProgress(Progress progress) =>
      dataSource.saveProgress(ProgressModel.fromEntity(progress));

  @override
  Future<void> clearProgress(String languageId) =>
      dataSource.clearProgress(languageId);
}
