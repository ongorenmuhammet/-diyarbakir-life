import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // Gerçek AdMob Reklam Birim Kimlikleri
  static const String _realBannerId = 'ca-app-pub-5340261426098742/9073750594';
  static const String _realInterstitialId = 'ca-app-pub-5340261426098742/6892552221';

  // Test Kimlikleri (Geliştirme / Debug modunda hesabın banlanmasını engellemek için)
  // Canlıya (Release) alındığında otomatik olarak gerçek kimlikler devreye girer.
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return _realBannerId;
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return _realInterstitialId;
  }

  // Zamanlayıcı kuralları
  DateTime? _appStartTime;
  DateTime? _lastInterstitialTime;
  static const int _initialDelaySeconds = 15; // Uygulama açılışından sonraki ilk bekleme süresi
  static const int _intervalSeconds = 120; // İki tam ekran reklam arasındaki minimum süre (2 dakika)

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  bool _isInitialized = false;

  /// AdMob SDK'sını güvenle başlatır
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _appStartTime = DateTime.now();
      _isInitialized = true;
      debugPrint('[AdService] MobileAds başarıyla başlatıldı.');
      loadInterstitialAd();
    } catch (e) {
      debugPrint('[AdService] MobileAds başlatma hatası: $e');
    }
  }

  /// Arka planda bir sonraki geçiş reklamını hazırlar
  void loadInterstitialAd() {
    if (_interstitialAd != null || _isInterstitialLoading) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          debugPrint('[AdService] Geçiş reklamı yüklendi ve hazır.');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _lastInterstitialTime = DateTime.now();
              // Bir sonraki reklam için hemen arkada yükleme başlat
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('[AdService] Reklam gösterilemedi: $error');
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
          debugPrint('[AdService] Geçiş reklamı yüklenemedi: $error');
        },
      ),
    );
  }

  /// Kullanıcı bir öğeye tıkladığında reklam kuralını kontrol eder:
  /// 1. Uygulama açılalı en az 15 saniye geçti mi?
  /// 2. Son reklamdan sonra en az 2 dakika (120 sn) geçti mi?
  /// 3. Reklam hazır mı?
  /// Eğer kurallar sağlanırsa reklamı gösterir, sağlanmazsa kullanıcıyı bekletmeden işlemine devam ettirir.
  void showInterstitialIfAllowed({VoidCallback? onComplete}) {
    final now = DateTime.now();

    // 1. Kural: Açılıştan sonra 15 saniye geçti mi?
    if (_appStartTime != null && now.difference(_appStartTime!).inSeconds < _initialDelaySeconds) {
      debugPrint('[AdService] İlk 15 saniye dolmadı. Reklam gösterilmedi.');
      onComplete?.call();
      return;
    }

    // 2. Kural: Son reklamdan bu yana 2 dakika geçti mi?
    if (_lastInterstitialTime != null && now.difference(_lastInterstitialTime!).inSeconds < _intervalSeconds) {
      final kalanSaniye = _intervalSeconds - now.difference(_lastInterstitialTime!).inSeconds;
      debugPrint('[AdService] 2 dakikalık aralık dolmadı. Kalan: $kalanSaniye sn.');
      onComplete?.call();
      return;
    }

    // 3. Kural: Reklam hazır mı?
    if (_interstitialAd != null) {
      debugPrint('[AdService] Kurallar sağlandı. Geçiş reklamı gösteriliyor...');
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _lastInterstitialTime = DateTime.now();
          loadInterstitialAd();
          onComplete?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('[AdService] Gösterim hatası: $error');
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
          onComplete?.call();
        },
      );
      _interstitialAd!.show();
    } else {
      // Reklam o an hazır değilse kullanıcıyı bekletme, arkada yükle
      loadInterstitialAd();
      onComplete?.call();
    }
  }
}

/// Ekranların altında sabit duran, Apple ve Google standartlarına uygun Banner Reklam Bileşeni
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdBannerWidget] Banner yüklenemedi: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink(); // Reklam gelene kadar boşluk bırakmaz, arayüzü bozmaz
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
