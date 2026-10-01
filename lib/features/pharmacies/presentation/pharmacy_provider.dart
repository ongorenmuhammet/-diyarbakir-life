import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/districts.dart';
import '../domain/pharmacy_model.dart';

class PharmaciesNotifier extends StateNotifier<AsyncValue<List<PharmacyModel>>> {
  static const _cacheKeyPrefix = 'pharmacies_daily_cache_';

  PharmaciesNotifier() : super(const AsyncValue.loading()) {
    _initAndFetch();
  }

  String get _todayKey {
    final now = DateTime.now();
    return '$_cacheKeyPrefix${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _initAndFetch() async {
    // 1. Önce SharedPreferences içinde bugünün kaydedilmiş canlı verisi var mı bak
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedJson = prefs.getString(_todayKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(cachedJson);
        final cachedList = decoded.map((e) => PharmacyModel.fromJson(e as Map<String, dynamic>)).toList();
        if (cachedList.isNotEmpty) {
          state = AsyncValue.data(cachedList);
        }
      }
    } catch (_) {}

    // 2. Arka planda canlı veriyi internetten çek ve önbelleği güncelle
    await fetchPharmacies();
  }

  Future<void> fetchPharmacies() async {
    // Eğer hali hazırda veri yoksa yükleniyor yap
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }

    final targetUrl = 'https://www.eczaneler.gen.tr/iframe.php?lokasyon=21';
    final fallbackUrl = 'https://www.hurriyet.com.tr/nobetci-eczaneler/diyarbakir/';

    final headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
    };

    String? htmlContent;
    bool isEczanelerGenTr = false;

    // A. Doğrudan eczaneler.gen.tr resmi iframe widget'ını çek (Cloudflare engelsiz)
    try {
      final response = await http.get(Uri.parse(targetUrl), headers: headers).timeout(const Duration(seconds: 7));
      if (response.statusCode == 200 && response.body.contains('Eczanesi')) {
        htmlContent = response.body;
        isEczanelerGenTr = true;
      }
    } catch (_) {}

    // B. Web (CORS) veya Bağlantı Engeli Durumunda Alternatif Canlı Proxy'leri Dene
    if (htmlContent == null) {
      final proxies = [
        'https://corsproxy.io/?url=${Uri.encodeComponent(targetUrl)}',
        'https://api.allorigins.win/raw?url=${Uri.encodeComponent(targetUrl)}',
        'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(targetUrl)}',
        fallbackUrl,
      ];

      for (var proxy in proxies) {
        try {
          final res = await http.get(Uri.parse(proxy)).timeout(const Duration(seconds: 7));
          if (res.statusCode == 200 && (res.body.contains('Eczanesi') || res.body.contains('ecz-module-pharmacy-info'))) {
            htmlContent = res.body;
            isEczanelerGenTr = res.body.contains('Eczanesi') && !res.body.contains('ecz-module-pharmacy-info');
            break;
          }
        } catch (_) {}
      }
    }

    final List<PharmacyModel> liveList = [];
    final knownDistricts = ['Kayapınar', 'Bağlar', 'Yenişehir', 'Sur', 'Bismil', 'Ergani', 'Silvan', 'Çermik', 'Çınar', 'Dicle', 'Eğil', 'Hani', 'Hazro', 'Kocaköy', 'Kulp', 'Lice', 'Çüngüş'];

    // C. HTML Ayrıştırma
    if (htmlContent != null) {
      try {
        final document = parser.parse(htmlContent);

        if (isEczanelerGenTr) {
          final trs = document.querySelectorAll('tr');
          for (int i = 0; i < trs.length; i++) {
            final text = trs[i].text.replaceAll(RegExp(r'\s+'), ' ').trim();
            if (text.contains('Eczanesi')) {
              String name = text;
              String district = 'Kayapınar';

              final distMatch = RegExp(r'\(([^)]+)\)').firstMatch(text);
              if (distMatch != null) {
                final rawDist = distMatch.group(1)?.trim() ?? '';
                name = text.replaceAll('($rawDist)', '').trim();
                if (rawDist != 'Merkez') {
                  district = rawDist;
                }
              }

              String phone = '0412 000 00 00';
              if (i + 1 < trs.length) {
                phone = trs[i + 1].text.replaceAll(RegExp(r'\s+'), ' ').trim();
              }

              String address = 'Diyarbakır';
              if (i + 2 < trs.length) {
                address = trs[i + 2].text.replaceAll(RegExp(r'\s+'), ' ').trim();
              }

              if (district == 'Kayapınar' || district == 'Merkez') {
                for (var d in knownDistricts) {
                  if (_cleanTurkish(address).contains(_cleanTurkish(d))) {
                    district = d;
                    break;
                  }
                }
              }

              if (name.isNotEmpty) {
                liveList.add(PharmacyModel(
                  id: name.toLowerCase().replaceAll(' ', '-'),
                  name: name,
                  district: district,
                  address: address,
                  phone: phone,
                  latitude: 0.0,
                  longitude: 0.0,
                  hours: '24 Saat Nöbetçi',
                ));
              }
            }
          }
        } else {
          // Hürriyet Fallback Parser
          final boxes = document.querySelectorAll('.ecz-module-pharmacy-info');
          for (var box in boxes) {
            final name = box.querySelector('.ecz-module-pharmacy-name')?.text.trim() ?? '';
            String address = box.querySelector('.ecz-module-pharmacy-location')?.text.trim() ?? '';
            if (address.startsWith('Adres:')) address = address.substring(6).trim();
            String phone = box.querySelector('.ecz-module-pharmacy-contact')?.text.trim() ?? '';
            if (phone.startsWith('Telefon:')) phone = phone.substring(8).trim();

            String district = 'Kayapınar';
            final subtitle = box.querySelector('.ecz-module-pharmacy-subtitle')?.text.trim() ?? '';
            if (subtitle.contains('/')) {
              final parts = subtitle.split('/');
              if (parts.length > 1) district = parts[1].trim();
            } else {
              for (var d in knownDistricts) {
                if (_cleanTurkish(address).contains(_cleanTurkish(d))) {
                  district = d;
                  break;
                }
              }
            }

            if (name.isNotEmpty) {
              liveList.add(PharmacyModel(
                id: name.toLowerCase().replaceAll(' ', '-'),
                name: name,
                district: district,
                address: address.isNotEmpty ? address : 'Diyarbakır / $district',
                phone: phone.isNotEmpty ? phone : '0412 000 00 00',
                latitude: 0.0,
                longitude: 0.0,
                hours: '24 Saat Nöbetçi',
              ));
            }
          }
        }
      } catch (_) {}
    }

    // D. Canlı veri başarıyla alındıysa önbelleğe kaydet ve durumu güncelle
    if (liveList.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final String jsonStr = json.encode(liveList.map((e) => e.toJson()).toList());
        await prefs.setString(_todayKey, jsonStr);
      } catch (_) {}
      state = AsyncValue.data(liveList);
    } else if (!state.hasValue) {
      // İnternet veya canlı çekim tamamen başarısız olduysa hata göster
      state = AsyncError('Canlı nöbetçi eczane verileri çekilemedi. İnternet bağlantınızı kontrol edip yenileyin.', StackTrace.current);
    }
  }
}

final pharmacySearchQueryProvider = StateProvider<String>((ref) => '');

final pharmaciesListProvider = StateNotifierProvider<PharmaciesNotifier, AsyncValue<List<PharmacyModel>>>((ref) {
  return PharmaciesNotifier();
});

String _cleanTurkish(String text) {
  return text
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('i̇', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .trim();
}

final filteredPharmaciesProvider = Provider<AsyncValue<List<PharmacyModel>>>((ref) {
  final pharmaciesState = ref.watch(pharmaciesListProvider);
  final selectedDistrict = ref.watch(selectedDistrictProvider);
  final query = ref.watch(pharmacySearchQueryProvider);
  
  return pharmaciesState.whenData((pharmacies) {
    var filtered = pharmacies;
    if (selectedDistrict != 'Diyarbakır') {
      final cleanSelected = _cleanTurkish(selectedDistrict);
      filtered = filtered.where((ph) {
        final cleanPhDist = _cleanTurkish(ph.district);
        return cleanPhDist == cleanSelected || cleanPhDist.contains(cleanSelected) || cleanSelected.contains(cleanPhDist);
      }).toList();
    }
    
    if (query.trim().isNotEmpty) {
      final cleanQuery = _cleanTurkish(query);
      filtered = filtered.where((ph) {
        final cleanName = _cleanTurkish(ph.name);
        final cleanAddress = _cleanTurkish(ph.address);
        final cleanPhone = ph.phone;
        return cleanName.contains(cleanQuery) || cleanAddress.contains(cleanQuery) || cleanPhone.contains(cleanQuery);
      }).toList();
    }

    return filtered;
  });
});
