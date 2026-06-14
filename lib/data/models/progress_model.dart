import '../../domain/entities/progress.dart';

class ProgressModel extends Progress {
  const ProgressModel({
    required super.characterId,
    required super.languageId,
    required super.attemptCount,
    required super.successCount,
    required super.lastPracticed,
    required super.bestAccuracy,
  });

  factory ProgressModel.fromMap(Map<String, dynamic> map) {
    return ProgressModel(
      characterId: map['characterId'] as String,
      languageId: map['languageId'] as String,
      attemptCount: map['attemptCount'] as int,
      successCount: map['successCount'] as int,
      lastPracticed: DateTime.parse(map['lastPracticed'] as String),
      bestAccuracy: (map['bestAccuracy'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'characterId': characterId,
    'languageId': languageId,
    'attemptCount': attemptCount,
    'successCount': successCount,
    'lastPracticed': lastPracticed.toIso8601String(),
    'bestAccuracy': bestAccuracy,
  };

  factory ProgressModel.fromEntity(Progress p) => ProgressModel(
    characterId: p.characterId,
    languageId: p.languageId,
    attemptCount: p.attemptCount,
    successCount: p.successCount,
    lastPracticed: p.lastPracticed,
    bestAccuracy: p.bestAccuracy,
  );
}
