import 'package:get_it/get_it.dart';
import 'package:kid_write/Core/services/tts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/datasources/character_local_datasource.dart';
import 'data/datasources/progress_local_datasource.dart';
import 'data/repositories/character_repository_impl.dart';
import 'data/repositories/progress_repository_impl.dart';
import 'domain/repositories/character_repository.dart';
import 'domain/repositories/progress_repository.dart';
import 'domain/usecases/get_characters.dart';
import 'domain/usecases/get_languages.dart';
import 'domain/usecases/get_progress.dart';
import 'domain/usecases/save_progress.dart';
import 'Presentation/blocs/home/home_bloc.dart';
import 'Presentation/blocs/music/music_bloc.dart';
import 'Presentation/blocs/progress/progress_bloc.dart';
import 'Presentation/blocs/writing/writing_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  // Data sources
  sl.registerLazySingleton<CharacterLocalDataSource>(
        () => CharacterLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<ProgressLocalDataSource>(
        () => ProgressLocalDataSourceImpl(prefs: sl()),
  );

  // Repositories
  sl.registerLazySingleton<CharacterRepository>(
        () => CharacterRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<ProgressRepository>(
        () => ProgressRepositoryImpl(dataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCharacters(sl()));
  sl.registerLazySingleton(() => GetLanguages(sl()));
  sl.registerLazySingleton(() => GetProgress(sl()));
  sl.registerLazySingleton(() => SaveProgress(sl()));

  // BLoCs (factory — new instance per page)
  sl.registerFactory(() => HomeBloc(getLanguages: sl()));
  sl.registerFactory(() => WritingBloc());
  sl.registerFactory(
        () => ProgressBloc(getProgress: sl(), saveProgress: sl()),
  );
  sl.registerLazySingleton(() => MusicBloc(prefs: sl()));

  // TTS
  sl.registerLazySingleton(() => TtsService());
}

