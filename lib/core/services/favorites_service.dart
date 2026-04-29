import 'package:get_storage/get_storage.dart';

class FavoritesService {
  static const _key = 'fav_ids';
  final GetStorage _box = GetStorage();

  Set<int> read() {
    final list = _box.read<List>(_key) ?? <int>[];
    return list.map((e) => e as int).toSet();
  }

  void write(Set<int> ids) {
    _box.write(_key, ids.toList());
  }
}
