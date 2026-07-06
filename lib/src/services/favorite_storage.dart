import 'package:shared_preferences/shared_preferences.dart';

/// 收藏本地存储。
///
/// 使用 shared_preferences 是因为首版只需要保存少量点位 id，不需要数据库；
/// 这样可以满足“本地收藏”需求，同时避免引入和当前规模不匹配的存储复杂度。
class FavoriteStorage {
  FavoriteStorage(this._preferences);

  static const String _key = 'favorite_place_ids';

  final SharedPreferences _preferences;

  Set<String> loadFavoritePlaceIds() {
    return (_preferences.getStringList(_key) ?? const <String>[]).toSet();
  }

  Future<void> saveFavoritePlaceIds(Set<String> ids) {
    final sortedIds = ids.toList()..sort();
    return _preferences.setStringList(_key, sortedIds);
  }
}
