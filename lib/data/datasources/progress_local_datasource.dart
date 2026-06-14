import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress_model.dart';

abstract class ProgressLocalDataSource {
  ProgressModel? getProgress(String characterId, String languageId);
  List<ProgressModel> getAllProgress(String languageId);
  Future<void> saveProgress(ProgressModel progress);
  Future<void> clearProgress(String languageId);
}

class ProgressLocalDataSourceImpl implements ProgressLocalDataSource {
  final SharedPreferences prefs;
  ProgressLocalDataSourceImpl({required this.prefs});

  String _key(String characterId, String languageId) =>
      'progress_${languageId}_$characterId';

  String _allKey(String languageId) => 'progress_all_$languageId';

  @override
  ProgressModel? getProgress(String characterId, String languageId) {
    final json = prefs.getString(_key(characterId, languageId));
    if (json == null) return null;
    return ProgressModel.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  @override
  List<ProgressModel> getAllProgress(String languageId) {
    final keysJson = prefs.getString(_allKey(languageId));
    if (keysJson == null) return [];
    final keys = (jsonDecode(keysJson) as List).cast<String>();
    final result = <ProgressModel>[];
    for (final k in keys) {
      final json = prefs.getString(k);
      if (json != null) {
        result.add(ProgressModel.fromMap(
            jsonDecode(json) as Map<String, dynamic>));
      }
    }
    return result;
  }

  @override
  Future<void> saveProgress(ProgressModel progress) async {
    final key = _key(progress.characterId, progress.languageId);
    await prefs.setString(key, jsonEncode(progress.toMap()));

    // Update index
    final allKey = _allKey(progress.languageId);
    final keysJson = prefs.getString(allKey);
    final keys = keysJson != null
        ? (jsonDecode(keysJson) as List).cast<String>()
        : <String>[];
    if (!keys.contains(key)) {
      keys.add(key);
      await prefs.setString(allKey, jsonEncode(keys));
    }
  }

  @override
  Future<void> clearProgress(String languageId) async {
    final allKey = _allKey(languageId);
    final keysJson = prefs.getString(allKey);
    if (keysJson != null) {
      final keys = (jsonDecode(keysJson) as List).cast<String>();
      for (final k in keys) {
        await prefs.remove(k);
      }
      await prefs.remove(allKey);
    }
  }
}
