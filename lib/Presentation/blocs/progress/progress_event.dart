part of 'progress_bloc.dart';

abstract class ProgressEvent extends Equatable {
  const ProgressEvent();
  @override
  List<Object?> get props => [];
}

class ProgressLoad extends ProgressEvent {
  final String languageId;
  const ProgressLoad(this.languageId);
  @override
  List<Object?> get props => [languageId];
}

class ProgressRecord extends ProgressEvent {
  final String characterId;
  final String languageId;
  final bool success;
  final double accuracy;
  const ProgressRecord({
    required this.characterId,
    required this.languageId,
    required this.success,
    required this.accuracy,
  });
  @override
  List<Object?> get props => [characterId, languageId, success, accuracy];
}
