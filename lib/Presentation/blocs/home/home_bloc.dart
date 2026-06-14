import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/language.dart';
import '../../../domain/usecases/get_languages.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetLanguages getLanguages;

  HomeBloc({required this.getLanguages}) : super(const HomeInitial()) {
    on<HomeLoadLanguages>(_onLoad);
    on<HomeSelectLanguage>(_onSelect);
  }

  Future<void> _onLoad(
      HomeLoadLanguages event, Emitter<HomeState> emit) async {
    emit(const HomeLoading());
    try {
      final languages = await getLanguages();
      emit(HomeLoaded(languages: languages));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  void _onSelect(HomeSelectLanguage event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final current = state as HomeLoaded;
      emit(HomeLoaded(
        languages: current.languages,
        selectedLanguageId: event.languageId,
      ));
    }
  }
}
