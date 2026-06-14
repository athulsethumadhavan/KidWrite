part of 'music_bloc.dart';

class MusicState extends Equatable {
  final bool isMusicEnabled;
  final bool isSoundEnabled;
  final bool isPlaying;

  const MusicState({
    this.isMusicEnabled = true,
    this.isSoundEnabled = true,
    this.isPlaying = false,
  });

  MusicState copyWith({
    bool? isMusicEnabled,
    bool? isSoundEnabled,
    bool? isPlaying,
  }) =>
      MusicState(
        isMusicEnabled: isMusicEnabled ?? this.isMusicEnabled,
        isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
        isPlaying: isPlaying ?? this.isPlaying,
      );

  @override
  List<Object?> get props => [isMusicEnabled, isSoundEnabled, isPlaying];
}
