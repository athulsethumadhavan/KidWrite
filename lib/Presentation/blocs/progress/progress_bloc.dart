import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/progress.dart';
import '../../../domain/usecases/get_progress.dart';
import '../../../domain/usecases/save_progress.dart';

part 'progress_event.dart';
part 'progress_state.dart';

class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  final GetProgress getProgress;
  final SaveProgress saveProgress;

  ProgressBloc({required this.getProgress, required this.saveProgress})
      : super(const ProgressInitial()) {
    on<ProgressLoad>(_onLoad);
    on<ProgressRecord>(_onRecord);
  }

  Future<void> _onLoad(
      ProgressLoad event, Emitter<ProgressState> emit) async {
    final list = await getProgress.getAll(event.languageId);
    final map = {for (final p in list) p.characterId: p};
    emit(ProgressLoaded(map));
  }

  Future<void> _onRecord(
      ProgressRecord event, Emitter<ProgressState> emit) async {
    final existing = await getProgress(event.characterId, event.languageId);
    final now = DateTime.now();

    final updated = existing != null
        ? existing.copyWith(
      attemptCount: existing.attemptCount + 1,
      successCount:
      existing.successCount + (event.success ? 1 : 0),
      lastPracticed: now,
      bestAccuracy: event.accuracy > existing.bestAccuracy
          ? event.accuracy
          : existing.bestAccuracy,
    )
        : Progress(
      characterId: event.characterId,
      languageId: event.languageId,
      attemptCount: 1,
      successCount: event.success ? 1 : 0,
      lastPracticed: now,
      bestAccuracy: event.accuracy,
    );

    await saveProgress(updated);

    // Update in-memory map
    if (state is ProgressLoaded) {
      final current = (state as ProgressLoaded).progressMap;
      emit(ProgressLoaded({...current, event.characterId: updated}));
    }
  }
}
