import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/utils/weather_service.dart';
import '../../core/utils/location_service.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();

  WeatherData? _weather;
  String _tetAdvice = "Đang cập nhật thời tiết...";
  bool _isLoading = false;

  WeatherData? get weather => _weather;
  String get tetAdvice => _tetAdvice;
  bool get isLoading => _isLoading;

  Future<void> updateWeather() async {
    _isLoading = true;
    notifyListeners();

    try {
      final pos = await _locationService.getCurrentPosition();
      
      // Mặc định là Hà Nội (21.0285, 105.8542) nếu không lấy được GPS
      double lat = pos?.latitude ?? 21.0285;
      double lon = pos?.longitude ?? 105.8542;
      
      _weather = await _weatherService.fetchWeather(lat, lon);
      _tetAdvice = _weatherService.getTetAdvice(_weather);
      
      if (pos == null) {
        _tetAdvice = "[Dự báo Hà Nội] $_tetAdvice";
      }
    } catch (e) {
      debugPrint("❌ Lỗi WeatherProvider: $e");
      _tetAdvice = "Thời tiết đang bận một chút, bạn thử lại sau nhé! 🌤️";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
