part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class HomeLoadLanguages extends HomeEvent {
  const HomeLoadLanguages();
}

class HomeSelectLanguage extends HomeEvent {
  final String languageId;
  const HomeSelectLanguage(this.languageId);
  @override
  List<Object?> get props => [languageId];
}
