import 'package:geolocator/geolocator.dart';
import 'notification_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() => _instance;

  LocationService._internal();

  final NotificationService _notificationService = NotificationService();

  Future<void> init() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }
  }

  /// Mock geofencing check
  /// In a real app, this would use Geolocator.getPositionStream or Geofencing plugins
  void checkProximity(double marketLat, double marketLon, String marketName) async {
    Position position = await Geolocator.getCurrentPosition();
    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      marketLat,
      marketLon,
    );

    if (distanceInMeters < 500) { // 500m radius
      _notificationService.showNotification(
        id: marketName.hashCode,
        title: "🛒 Nhắc nhở mua sắm!",
        body: "Bạn đang ở gần $marketName. Đừng quên mua đồ Tết nhé!",
      );
    }
  }
}
