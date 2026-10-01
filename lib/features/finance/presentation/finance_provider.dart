import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../domain/finance_model.dart';

final financeProvider = AsyncNotifierProvider<FinanceNotifier, FinanceModel>(() {
  return FinanceNotifier();
});

class FinanceNotifier extends AsyncNotifier<FinanceModel> {
  Timer? _timer;
  DateTime? _lastFetchTime;

  @override
  Future<FinanceModel> build() async {
    _scheduleFetch();
    return await _fetchData();
  }

  void _scheduleFetch() {
    _timer?.cancel();
    
    // Her 1 dakikada bir kontrol eder, duruma göre API isteği atar.
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndFetch();
    });
    
    ref.onDispose(() {
      _timer?.cancel();
    });
  }
  
  Future<void> _checkAndFetch() async {
    final now = DateTime.now();
    
    // Hafta sonu veri çekme (Cumartesi = 6, Pazar = 7)
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return; 
    }

    final isWorkingHours = now.hour >= 9 && now.hour < 18;
    
    if (_lastFetchTime == null) {
       await _updateData();
       return;
    }

    final minutesSinceLastFetch = now.difference(_lastFetchTime!).inMinutes;

    if (isWorkingHours) {
      // Mesai içi: 30 dakikada bir
      if (minutesSinceLastFetch >= 30) {
        await _updateData();
      }
    } else {
      // Mesai dışı: 60 dakikada bir
      if (minutesSinceLastFetch >= 60) {
        await _updateData();
      }
    }
  }

  Future<void> _updateData() async {
    try {
      final newData = await _fetchData();
      state = AsyncData(newData);
    } catch (e, stack) {
      // İlk veri yoksa hata göster, varsa eski veriyi koru
      if (!state.hasValue) {
        state = AsyncError(e, stack);
      }
    }
  }

  Future<FinanceModel> _fetchData() async {
    _lastFetchTime = DateTime.now();

    // Varsayılan güncel yaklaşık değerler (sadece en son aşama için)
    double usd = 47.35;
    double eur = 53.89;
    double usdChange = 0.0;
    double eurChange = 0.0;
    double gold = 6220.00;
    double goldChange = 0.0;
    double silver = 89.20;
    double silverChange = 0.0;

    double parseDouble(dynamic value, double fallback) {
      if (value == null) return fallback;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? fallback;
      return fallback;
    }

    List<FinanceExtraItem> extras = [];

    final headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'application/json, text/plain, */*',
      'Accept-Encoding': 'gzip, deflate',
    };

    String? responseBody;

    // 1. Doğrudan API dene
    try {
      final trUrl = Uri.parse('https://finans.truncgil.com/v4/today.json');
      final trRes = await http.get(trUrl, headers: headers).timeout(const Duration(seconds: 8));
      if (trRes.statusCode == 200 && trRes.body.isNotEmpty) {
        responseBody = trRes.body;
      }
    } catch (e) {
      print('Direct Truncgil Fetch Error: $e');
    }

    // 2. Web (CORS) veya bağlantı hatası için Proxy yedekleri
    if (responseBody == null) {
      final proxies = [
        'https://api.allorigins.win/raw?url=${Uri.encodeComponent('https://finans.truncgil.com/v4/today.json')}',
        'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent('https://finans.truncgil.com/v4/today.json')}',
      ];

      for (var proxy in proxies) {
        try {
          final res = await http.get(Uri.parse(proxy)).timeout(const Duration(seconds: 8));
          if (res.statusCode == 200 && res.body.contains('USD')) {
            responseBody = res.body;
            break;
          }
        } catch (_) {}
      }
    }

    Map<String, FinanceExtraItem> extraMap = {
      'CEYREKALTIN': const FinanceExtraItem(label: 'Çeyrek Altın', price: 10108.59, change: 0.0),
      'YARIMALTIN': const FinanceExtraItem(label: 'Yarım Altın', price: 20217.17, change: 0.0),
      'TAMALTIN': const FinanceExtraItem(label: 'Tam Altın', price: 40310.69, change: 0.0),
      'CUMHURIYETALTINI': const FinanceExtraItem(label: 'Cumhuriyet Altını', price: 41603.00, change: 0.0),
      'GBP': const FinanceExtraItem(label: 'Sterlin (GBP)', price: 63.00, change: 0.0),
      'CHF': const FinanceExtraItem(label: 'İsviçre Frangı', price: 57.81, change: 0.0),
      'JPY': const FinanceExtraItem(label: 'Japon Yeni', price: 0.29, change: 0.0),
    };

    if (responseBody != null) {
      try {
        final data = jsonDecode(responseBody);
        
        if (data['USD'] != null) {
          usd = parseDouble(data['USD']['Selling'], usd);
          usdChange = parseDouble(data['USD']['Change'], usdChange);
        }
        if (data['EUR'] != null) {
          eur = parseDouble(data['EUR']['Selling'], eur);
          eurChange = parseDouble(data['EUR']['Change'], eurChange);
        }
        if (data['GRA'] != null) {
          gold = parseDouble(data['GRA']['Selling'], gold);
          goldChange = parseDouble(data['GRA']['Change'], goldChange);
        }
        if (data['GUMUS'] != null) {
          silver = parseDouble(data['GUMUS']['Selling'], silver);
          silverChange = parseDouble(data['GUMUS']['Change'], silverChange);
        }

        void updateExtra(String label, String key) {
          if (data[key] != null) {
            extraMap[key] = FinanceExtraItem(
              label: label,
              price: parseDouble(data[key]['Selling'], 0.0),
              change: parseDouble(data[key]['Change'], 0.0),
            );
          }
        }

        updateExtra('Çeyrek Altın', 'CEYREKALTIN');
        updateExtra('Yarım Altın', 'YARIMALTIN');
        updateExtra('Tam Altın', 'TAMALTIN');
        updateExtra('Cumhuriyet Altını', 'CUMHURIYETALTINI');
        updateExtra('Sterlin (GBP)', 'GBP');
        updateExtra('İsviçre Frangı', 'CHF');
        updateExtra('Japon Yeni', 'JPY');
      } catch (e) {
        print('JSON Decode Error: $e');
      }
    }

    extras = extraMap.values.toList();

    return FinanceModel(
      usd: usd,
      usdChange: usdChange,
      eur: eur,
      eurChange: eurChange,
      gold: gold,
      goldChange: goldChange,
      silver: silver,
      silverChange: silverChange,
      extras: extras,
    );
  }
}
