part of 'writing_bloc.dart';

enum WritingStatus { idle, drawing, checking, success, failure }

// 'checking' = pixel comparison in progress (async)

class WritingState extends Equatable {
  final Character? character;
  final List<List<Offset>> strokes; // each sub-list is one stroke
  final List<Offset> currentStroke;
  final WritingStatus status;
  final double accuracy; // 0.0 – 1.0
  final int attemptCount;

  /// Average thickness of the letter's own strokes, as a fraction of the
  /// canvas side (0 = not measured yet). The child's ink is drawn at 60% of
  /// this so it fits nicely inside the letter path.
  final double glyphStrokeWidth;

  /// Guided tracing (English & numbers): the letter's strokes in school
  /// writing order, normalized 0..1 and aligned to the displayed glyph.
  /// Empty → free tracing with the Done button (Indic scripts).
  final List<List<Offset>> guideStrokes;

  /// The letter's full shape. Usually the same as [guideStrokes], but for
  /// Malayalam the guide is cut where the pen doubles back, while the shape
  /// stays whole so the letter is drawn without gaps.
  final List<List<Offset>> shapeStrokes;

  /// Which stroke the child should draw next.
  final int targetStrokeIndex;

  /// True right after a drawn stroke didn't follow the demonstrated line.
  final bool strokeMissed;

  /// Free-draw challenge (3rd star): no hand, no dots, and strokes may be
  /// drawn in any order — we only check that the finished drawing covers
  /// the whole letter.
  final bool freeDraw;

  const WritingState({
    this.character,
    this.strokes = const [],
    this.currentStroke = const [],
    this.status = WritingStatus.idle,
    this.accuracy = 0,
    this.attemptCount = 0,
    this.glyphStrokeWidth = 0,
    this.guideStrokes = const [],
    this.shapeStrokes = const [],
    this.targetStrokeIndex = 0,
    this.strokeMissed = false,
    this.freeDraw = false,
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
    List<List<Offset>>? shapeStrokes,
    int? targetStrokeIndex,
    bool? strokeMissed,
    bool? freeDraw,
  }) => WritingState(
    character: character ?? this.character,
    strokes: strokes ?? this.strokes,
    currentStroke: currentStroke ?? this.currentStroke,
    status: status ?? this.status,
    accuracy: accuracy ?? this.accuracy,
    attemptCount: attemptCount ?? this.attemptCount,
    glyphStrokeWidth: glyphStrokeWidth ?? this.glyphStrokeWidth,
    guideStrokes: guideStrokes ?? this.guideStrokes,
    shapeStrokes: shapeStrokes ?? this.shapeStrokes,
    targetStrokeIndex: targetStrokeIndex ?? this.targetStrokeIndex,
    strokeMissed: strokeMissed ?? this.strokeMissed,
    freeDraw: freeDraw ?? this.freeDraw,
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
    shapeStrokes,
    targetStrokeIndex,
    strokeMissed,
    freeDraw,
  ];
}
