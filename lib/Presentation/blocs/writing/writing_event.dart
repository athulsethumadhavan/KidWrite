part of 'writing_bloc.dart';

abstract class WritingEvent extends Equatable {
  const WritingEvent();
  @override
  List<Object?> get props => [];
}

class WritingLoadCharacter extends WritingEvent {
  final Character character;
  const WritingLoadCharacter(this.character);
  @override
  List<Object?> get props => [character];
}

class WritingStrokeStarted extends WritingEvent {
  final Offset point;

  /// Canvas side length — needed to map the touch point onto the glyph
  /// mask so ink only registers inside the letter.
  final double canvasSize;
  const WritingStrokeStarted(this.point, this.canvasSize);
  @override
  List<Object?> get props => [point, canvasSize];
}

class WritingStrokeUpdated extends WritingEvent {
  final Offset point;
  final double canvasSize;
  const WritingStrokeUpdated(this.point, this.canvasSize);
  @override
  List<Object?> get props => [point, canvasSize];
}

class WritingStrokeEnded extends WritingEvent {
  /// Needed to validate guided strokes against the demonstrated line.
  final Size canvasSize;
  const WritingStrokeEnded(this.canvasSize);
  @override
  List<Object?> get props => [canvasSize];
}

class WritingCheckAccuracy extends WritingEvent {
  final Size canvasSize;
  const WritingCheckAccuracy(this.canvasSize);
  @override
  List<Object?> get props => [canvasSize];
}

class WritingClear extends WritingEvent {
  const WritingClear();
}

class WritingNextCharacter extends WritingEvent {
  final Character character;
  const WritingNextCharacter(this.character);
  @override
  List<Object?> get props => [character];
}
