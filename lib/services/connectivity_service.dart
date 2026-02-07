import 'package:flutter/cupertino.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService with ChangeNotifier {
  bool _isOffline = false;
  bool get isOffline => _isOffline;

  ConnectivityService() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
       // Check if any result indicates connectivity
       // Note: onConnectivityChanged emits a list now in newer versions.
       // If list contains 'none', we might be offline, BUT strictly speaking
       // if it contains 'mobile' or 'wifi' or 'ethernet', we are online.
       // It's safer to check if NONE of the results are valid connections.
       
       bool hasConnection = results.any((result) => 
         result == ConnectivityResult.mobile || 
         result == ConnectivityResult.wifi || 
         result == ConnectivityResult.ethernet || 
         result == ConnectivityResult.vpn
       );

       _isOffline = !hasConnection;
       notifyListeners();
    });
  }
  
  // Method to manually check status (e.g., on app start)
  Future<void> checkStatus() async {
    final results = await Connectivity().checkConnectivity();
    bool hasConnection = results.any((result) => 
         result == ConnectivityResult.mobile || 
         result == ConnectivityResult.wifi || 
         result == ConnectivityResult.ethernet || 
         result == ConnectivityResult.vpn
    );
    _isOffline = !hasConnection;
    notifyListeners();
  }
}
