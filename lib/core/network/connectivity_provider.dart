import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityNotifier extends StateNotifier<bool> {
  Timer? _timer;

  ConnectivityNotifier() : super(true) {
    _checkConnection();
    // Check connection every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _checkConnection());
  }

  Future<void> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 4),
      );
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        if (!state) state = true;
      } else {
        if (state) state = false;
      }
    } catch (_) {
      if (state) state = false;
    }
  }

  Future<bool> forceCheck() async {
    await _checkConnection();
    return state;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final isOnlineProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});
