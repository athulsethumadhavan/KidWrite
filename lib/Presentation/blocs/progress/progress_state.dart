part of 'progress_bloc.dart';

abstract class ProgressState extends Equatable {
  const ProgressState();
  @override
  List<Object?> get props => [];
}

class ProgressInitial extends ProgressState {
  const ProgressInitial();
}

class ProgressLoaded extends ProgressState {
  final Map<String, Progress> progressMap; // characterId → Progress
  const ProgressLoaded(this.progressMap);
  @override
  List<Object?> get props => [progressMap];
}
