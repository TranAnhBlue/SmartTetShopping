import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        if (weatherProvider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: Colors.white70),
            ),
          );
        }

        final weather = weatherProvider.weather;
        final advice = weatherProvider.tetAdvice;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Weather Icon Area
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: _getWeatherIcon(weather?.condition ?? ""),
              ),
              const SizedBox(width: 16),
              // Content Area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          weather != null ? "${weather.temp.toInt()}°C - ${weather.city}" : "Thời tiết Tết",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (weather != null)
                          Text(
                            _translateCondition(weather.condition),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      advice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white60, size: 18),
                onPressed: () => weatherProvider.updateWeather(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getWeatherIcon(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('rain') || cond.contains('drizzle')) {
      return const Icon(Icons.cloudy_snowing, color: Colors.blueAccent, size: 30);
    }
    if (cond.contains('clear')) {
      return const Icon(Icons.wb_sunny, color: Colors.yellowAccent, size: 30);
    }
    if (cond.contains('cloud')) {
      return const Icon(Icons.cloud, color: Colors.white, size: 30);
    }
    return const Icon(Icons.wb_cloudy_outlined, color: Colors.white70, size: 30);
  }

  String _translateCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear': return 'Trời quang';
      case 'clouds': return 'Nhiều mây';
      case 'rain': return 'Có mưa';
      case 'drizzle': return 'Mưa phùn';
      case 'thunderstorm': return 'Có dông';
      default: return condition;
    }
  }
}
