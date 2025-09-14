import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddressInfo {
  final String id;
  final String label;
  final String address;
  final double lat;
  final double lng;
  AddressInfo({required this.id, required this.label, required this.address, required this.lat, required this.lng});
  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'address': address, 'lat': lat, 'lng': lng};
  static AddressInfo fromJson(Map<String, dynamic> m) => AddressInfo(
        id: m['id'] as String,
        label: m['label'] as String,
        address: m['address'] as String,
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
      );
}

class AddressStorage {
  static const _kSaved = 'saved_addresses_v1';
  static const _kActive = 'active_address_id_v1';

  static Future<List<AddressInfo>> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_kSaved);
    if (data == null || data.isEmpty) return [];
    final list = (jsonDecode(data) as List<dynamic>).cast<Map<String, dynamic>>();
    return list.map(AddressInfo.fromJson).toList();
  }

  static Future<void> saveAll(List<AddressInfo> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSaved, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<void> setActive(AddressInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActive, info.id);
    await prefs.setDouble('loc_lat', info.lat);
    await prefs.setDouble('loc_lng', info.lng);
    await prefs.setString('loc_address', info.address);
  }

  static Future<AddressInfo?> getActive() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kActive);
    if (id == null) return null;
    final list = await loadSaved();
    try {
      return list.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getActiveId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kActive);
  }

  static Future<void> delete(String id) async {
    final list = await loadSaved();
    list.removeWhere((e) => e.id == id);
    await saveAll(list);
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_kActive) == id) {
      prefs.remove(_kActive);
    }
  }
}


