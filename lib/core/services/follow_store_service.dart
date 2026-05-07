import 'package:get_storage/get_storage.dart';

class FollowStore {
  static const _key = 'followed_shops';
  final GetStorage _box;

  FollowStore({GetStorage? box}) : _box = box ?? GetStorage();

  List<String> _list() => List<String>.from(_box.read<List>(_key) ?? const []);

  bool isFollowed(String slug) {
    final items = _list();
    return items.contains(slug);
  }

  void setFollowed(String slug, bool followed) {
    final items = _list();
    if (followed) {
      if (!items.contains(slug)) items.add(slug);
    } else {
      items.remove(slug);
    }
    _box.write(_key, items);
  }

  void clearAllFollowed() {
    _box.remove(_key);
  }
}
