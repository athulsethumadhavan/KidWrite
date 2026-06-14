import 'package:audioplayers/audioplayers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kid_write/Core/Constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'music_event.dart';
part 'music_state.dart';

class MusicBloc extends Bloc<MusicEvent, MusicState> {
  final SharedPreferences prefs;
  final AudioPlayer _bgPlayer = AudioPlayer();
  final AudioPlayer _fxPlayer = AudioPlayer();

  MusicBloc({required this.prefs}) : super(const MusicState()) {
    on<MusicInitialize>(_onInit);
    on<MusicToggle>(_onToggle);
    on<MusicPlaySuccess>(_onSuccess);
    on<MusicPlayTap>(_onTap);
  }

  Future<void> _onInit(
      MusicInitialize event, Emitter<MusicState> emit) async {
    final musicOn = prefs.getBool(AppConstants.prefMusicEnabled) ?? true;
    final soundOn = prefs.getBool(AppConstants.prefSoundEnabled) ?? true;
    emit(MusicState(isMusicEnabled: musicOn, isSoundEnabled: soundOn));

    if (musicOn) {
      await _startBgMusic();
      emit(state.copyWith(isPlaying: true));
    }
  }

  Future<void> _onToggle(
      MusicToggle event, Emitter<MusicState> emit) async {
    final newEnabled = !state.isMusicEnabled;
    await prefs.setBool(AppConstants.prefMusicEnabled, newEnabled);

    if (newEnabled) {
      await _startBgMusic();
      emit(state.copyWith(isMusicEnabled: true, isPlaying: true));
    } else {
      await _bgPlayer.stop();
      emit(state.copyWith(isMusicEnabled: false, isPlaying: false));
    }
  }

  Future<void> _onSuccess(
      MusicPlaySuccess event, Emitter<MusicState> emit) async {
    if (!state.isSoundEnabled) return;
    try {
      await _fxPlayer.play(AssetSource(AppConstants.successSoundPath));
    } catch (_) {}
  }

  Future<void> _onTap(
      MusicPlayTap event, Emitter<MusicState> emit) async {
    if (!state.isSoundEnabled) return;
    try {
      await _fxPlayer.play(AssetSource(AppConstants.tapSoundPath));
    } catch (_) {}
  }

  Future<void> _startBgMusic() async {
    try {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.play(AssetSource(AppConstants.bgMusicPath));
    } catch (_) {
      // Audio files may not be present in dev — silently ignore
    }
  }

  @override
  Future<void> close() async {
    await _bgPlayer.dispose();
    await _fxPlayer.dispose();
    return super.close();
  }
}
