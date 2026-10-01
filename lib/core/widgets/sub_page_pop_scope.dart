import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ads/ad_service.dart';

/// Alt sayfalar için güvenli geri tuşu koruyucusu ve reklam tetikleyicisi.
/// Eğer sayfa geçmişinde geri dönülecek ekran varsa (canPop == true) geri döner.
/// Eğer sayfa geçmişi yoksa (doğrudan link, bildirim veya context.go ile açıldıysa)
/// uygulamadan çıkmak yerine güvenle Ana Sayfaya (/home) yönlendirir.
class SubPagePopScope extends StatefulWidget {
  final Widget child;
  final String fallbackRoute;

  const SubPagePopScope({
    super.key,
    required this.child,
    this.fallbackRoute = '/home',
  });

  @override
  State<SubPagePopScope> createState() => _SubPagePopScopeState();
}

class _SubPagePopScopeState extends State<SubPagePopScope> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdService.instance.showInterstitialIfAllowed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;

        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          context.go(widget.fallbackRoute);
        }
      },
      child: widget.child,
    );
  }
}
