import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class NetworkStatusService extends GetxService with WidgetsBindingObserver {
  NetworkStatusService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final RxBool hasNetwork = true.obs;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _offlineDebounce;

  Future<NetworkStatusService> init() async {
    WidgetsBinding.instance.addObserver(this);
    _subscription = _connectivity.onConnectivityChanged.listen(
      _update,
      onError: (Object error) => debugPrint('[NetworkStatus] Stream error: $error'),
    );
    unawaited(_refresh());
    return this;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    try {
      _update(await _connectivity.checkConnectivity());
    } catch (error) {
      debugPrint('[NetworkStatus] Could not check connection: $error');
    }
  }

  void _update(List<ConnectivityResult> results) {
    final bool connected =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);
    if (connected) {
      _offlineDebounce?.cancel();
      hasNetwork.value = true;
    } else {
      _offlineDebounce?.cancel();
      _offlineDebounce = Timer(
        const Duration(milliseconds: 500),
        () => hasNetwork.value = false,
      );
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _offlineDebounce?.cancel();
    _subscription?.cancel();
    super.onClose();
  }
}
