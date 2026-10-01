import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<String> kDistricts = [
  'Diyarbakır',
  'Kayapınar',
  'Sur',
  'Yenişehir',
  'Bağlar',
  'Bismil',
  'Ergani',
  'Silvan',
  'Çınar',
];

class SelectedDistrictNotifier extends StateNotifier<String> {
  static const String _key = 'selected_district';

  SelectedDistrictNotifier() : super('Diyarbakır') {
    _loadDistrict();
  }

  Future<void> _loadDistrict() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null && kDistricts.contains(saved)) {
        state = saved;
      }
    } catch (_) {}
  }

  Future<void> setDistrict(String district) async {
    state = district;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, district);
    } catch (_) {}
  }
}

final selectedDistrictProvider =
    StateNotifierProvider<SelectedDistrictNotifier, String>((ref) {
  return SelectedDistrictNotifier();
});
