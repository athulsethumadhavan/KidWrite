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

  /// Average thickness of the letter's own strokes, as a fraction of the
  /// canvas side (0 = not measured yet). The child's ink is drawn at 60% of
  /// this so it fits nicely inside the letter path.
  final double glyphStrokeWidth;

  /// Guided tracing (English & numbers): the letter's strokes in school
  /// writing order, normalized 0..1 and aligned to the displayed glyph.
  /// Empty → free tracing with the Done button (Indic scripts).
  final List<List<Offset>> guideStrokes;

  /// Which stroke the child should draw next.
  final int targetStrokeIndex;

  /// True right after a drawn stroke didn't follow the demonstrated line.
  final bool strokeMissed;

  const WritingState({
    this.character,
    this.strokes = const [],
    this.currentStroke = const [],
    this.status = WritingStatus.idle,
    this.accuracy = 0,
    this.attemptCount = 0,
    this.glyphStrokeWidth = 0,
    this.guideStrokes = const [],
    this.targetStrokeIndex = 0,
    this.strokeMissed = false,
  });

  bool get isGuided => guideStrokes.isNotEmpty;

  WritingState copyWith({
    Character? character,
    List<List<Offset>>? strokes,
    List<Offset>? currentStroke,
    WritingStatus? status,
    double? accuracy,
    int? attemptCount,
    double? glyphStrokeWidth,
    List<List<Offset>>? guideStrokes,
    int? targetStrokeIndex,
    bool? strokeMissed,
  }) =>
      WritingState(
        character: character ?? this.character,
        strokes: strokes ?? this.strokes,
        currentStroke: currentStroke ?? this.currentStroke,
        status: status ?? this.status,
        accuracy: accuracy ?? this.accuracy,
        attemptCount: attemptCount ?? this.attemptCount,
        glyphStrokeWidth: glyphStrokeWidth ?? this.glyphStrokeWidth,
        guideStrokes: guideStrokes ?? this.guideStrokes,
        targetStrokeIndex: targetStrokeIndex ?? this.targetStrokeIndex,
        strokeMissed: strokeMissed ?? this.strokeMissed,
      );

  @override
  List<Object?> get props => [
    character,
    strokes,
    currentStroke,
    status,
    accuracy,
    attemptCount,
    glyphStrokeWidth,
    guideStrokes,
    targetStrokeIndex,
    strokeMissed,
  ];
}
