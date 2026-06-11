import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class LocationService {
  static LocationService instance() => Get.isRegistered<LocationService>()
      ? Get.find<LocationService>()
      : Get.put(LocationService());

  /// Returns the device's current position, or null if permission is denied
  /// or the location cannot be determined within the timeout.
  Future<Position?> getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
