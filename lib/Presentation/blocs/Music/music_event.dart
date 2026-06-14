part of 'music_bloc.dart';

abstract class MusicEvent extends Equatable {
  const MusicEvent();
  @override
  List<Object?> get props => [];
}

class MusicInitialize extends MusicEvent {
  const MusicInitialize();
}

class MusicToggle extends MusicEvent {
  const MusicToggle();
}

class MusicPlaySuccess extends MusicEvent {
  const MusicPlaySuccess();
}

class MusicPlayTap extends MusicEvent {
  const MusicPlayTap();
}