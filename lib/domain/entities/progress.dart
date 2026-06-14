import 'package:equatable/equatable.dart';

class Progress extends Equatable {
  final String characterId;
  final String languageId;
  final int attemptCount;
  final int successCount;
  final DateTime lastPracticed;
  final double bestAccuracy; // 0.0 – 1.0

  const Progress({
    required this.characterId,
    required this.languageId,
    required this.attemptCount,
    required this.successCount,
    required this.lastPracticed,
    required this.bestAccuracy,
  });

  bool get isMastered => successCount >= 3 && bestAccuracy >= 0.8;

  double get successRate =>
      attemptCount == 0 ? 0 : successCount / attemptCount;

  Progress copyWith({
    int? attemptCount,
    int? successCount,
    DateTime? lastPracticed,
    double? bestAccuracy,
  }) {
    return Progress(
      characterId: characterId,
      languageId: languageId,
      attemptCount: attemptCount ?? this.attemptCount,
      successCount: successCount ?? this.successCount,
      lastPracticed: lastPracticed ?? this.lastPracticed,
      bestAccuracy: bestAccuracy ?? this.bestAccuracy,
    );
  }

  @override
  List<Object?> get props => [characterId, languageId];
}
