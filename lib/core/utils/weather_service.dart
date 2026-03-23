import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../constants/api_keys.dart';

class WeatherData {
  final double temp;
  final String condition;
  final String icon;
  final String city;

  WeatherData({
    required this.temp,
    required this.condition,
    required this.icon,
    required this.city,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temp: (json['current']['temp_c'] as num).toDouble(),
      condition: json['current']['condition']['text'],
      icon: "https:${json['current']['condition']['icon']}", // WeatherAPI icon starts with //
      city: json['location']['name'],
    );
  }
}

class WeatherService {
  // Chuyển sang WeatherAPI.com theo key của bạn
  static const String _baseUrl = 'https://api.weatherapi.com/v1/current.json';

  Future<WeatherData?> fetchWeather(double lat, double lon) async {
    final apiKey = ApiKeys.openWeatherMap;
    if (apiKey.isEmpty || apiKey.contains("YOUR_")) {
      return null;
    }

    try {
      final url = '$_baseUrl?key=$apiKey&q=$lat,$lon&lang=vi';
      debugPrint("🌤️ Fetching weather (WeatherAPI): $url");
      final response = await http.get(Uri.parse(url));
      debugPrint("🌤️ Weather Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        return WeatherData.fromJson(jsonDecode(response.body));
      } else {
        debugPrint("❌ Weather API Error: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Weather Exception: $e");
      return null;
    }
  }

  String getTetAdvice(WeatherData? weather) {
    if (weather == null) return "Chúc bạn một ngày sắm Tết vui vẻ!";
    
    final condition = weather.condition.toLowerCase();
    final temp = weather.temp;

    if (condition.contains('rain') || condition.contains('drizzle')) {
      return "Trời có mưa nhỏ, bạn nhớ mang ô khi đi sắm Tết nhé! 🌧️";
    }
    
    if (temp > 28) {
      return "Trời khá nắng nóng, thích hợp sắm đồ uống giải khát và mứt Tết! ☀️";
    }

    if (temp < 15) {
      return "Trời khá lạnh, rất hợp để đi dạo phố sắm đào và ăn bát phở nóng! ❄️";
    }

    if (condition.contains('clear') || condition.contains('cloud')) {
      return "Hôm nay trời nắng đẹp, rất thích hợp để đi sắm hoa Tết! 🌸";
    }

    return "Thời tiết thuận lợi, chúc bạn sắm sửa được nhiều đồ ưng ý! 🎋";
  }
}
