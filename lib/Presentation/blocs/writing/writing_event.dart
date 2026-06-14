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
  const WritingStrokeStarted(this.point);
  @override
  List<Object?> get props => [point];
}

class WritingStrokeUpdated extends WritingEvent {
  final Offset point;
  const WritingStrokeUpdated(this.point);
  @override
  List<Object?> get props => [point];
}

class WritingStrokeEnded extends WritingEvent {
  const WritingStrokeEnded();
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
