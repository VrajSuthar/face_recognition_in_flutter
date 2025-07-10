import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxController {
  var isConnected = true.obs;

  @override
  void onInit() {
    super.onInit();
    checkConnectivity();
  }

  void checkConnectivity() async {
    var results = await Connectivity().checkConnectivity();
    isConnected.value = results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi);
    print("Checked Connectivity: ${isConnected.value}");
  }
}
