part of 'writing_bloc.dart';

enum WritingStatus { idle, drawing, checking, success, failure }

// 'checking' = pixel comparison in progress (async)

class WritingState extends Equatable {
  final Character? character;
  final List<List<Offset>> strokes;     // each sub-list is one stroke
  final List<Offset> currentStroke;
  final WritingStatus status;
  final double accuracy;                // 0.0 – 1.0
  final int attemptCount;

  const WritingState({
    this.character,
    this.strokes = const [],
    this.currentStroke = const [],
    this.status = WritingStatus.idle,
    this.accuracy = 0,
    this.attemptCount = 0,
  });

  WritingState copyWith({
    Character? character,
    List<List<Offset>>? strokes,
    List<Offset>? currentStroke,
    WritingStatus? status,
    double? accuracy,
    int? attemptCount,
  }) =>
      WritingState(
        character: character ?? this.character,
        strokes: strokes ?? this.strokes,
        currentStroke: currentStroke ?? this.currentStroke,
        status: status ?? this.status,
        accuracy: accuracy ?? this.accuracy,
        attemptCount: attemptCount ?? this.attemptCount,
      );

  @override
  List<Object?> get props =>
      [character, strokes, currentStroke, status, accuracy, attemptCount];
}
