import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _apiKey = '853173f9b88892d978ed72b263dc7b33'; // Your OpenWeather API key
  
  // Cache weather data for 10 minutes (as recommended by OpenWeather)
  static Map<String, dynamic>? _cachedWeather;
  static DateTime? _lastFetchTime;
  static const Duration _cacheTimeout = Duration(minutes: 10);
  
  /// Get current weather by coordinates
  static Future<Map<String, dynamic>?> getCurrentWeather({
    double? lat,
    double? lon,
    String? cityName,
  }) async {
    try {
      // Check cache first (OpenWeather recommends not calling more than once per 10 minutes)
      if (_isCacheValid()) {
        print('Using cached weather data');
        return _cachedWeather;
      }

      String url;
      
      if (lat != null && lon != null) {
        // Use coordinates for precise location (recommended by OpenWeather)
        url = '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
      } else if (cityName != null) {
        url = '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric';
      } else {
        // Try to get current location
        Position? position = await _getCurrentLocation();
        if (position == null) return null;
        
        url = '$_baseUrl/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric';
      }

      print('Calling OpenWeather API: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weatherData = _parseCurrentWeather(data);
        
        // Cache the result
        _cachedWeather = weatherData;
        _lastFetchTime = DateTime.now();
        
        return weatherData;
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        print('OpenWeather API rate limit exceeded. Please wait 10 minutes.');
        return null;
      } else if (response.statusCode == 401) {
        // Invalid API key
        print('Invalid OpenWeather API key. Please check your configuration.');
        print('Note: New API keys can take 1-2 hours to activate after signup.');
        return null;
      } else {
        print('Weather API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting current weather: $e');
      return null;
    }
  }

  /// Get weather forecast (5 days)
  static Future<List<Map<String, dynamic>>> getWeatherForecast({
    double? lat,
    double? lon,
    String? cityName,
  }) async {
    try {
      // Check if API key is configured
      if (!isApiKeyConfigured()) {
        print('OpenWeather API key not configured');
        return [];
      }

      String url;
      
      if (lat != null && lon != null) {
        // Use coordinates for precise location (recommended by OpenWeather)
        url = '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
      } else if (cityName != null) {
        url = '$_baseUrl/forecast?q=$cityName&appid=$_apiKey&units=metric';
      } else {
        Position? position = await _getCurrentLocation();
        if (position == null) return [];
        
        url = '$_baseUrl/forecast?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric';
      }

      print('Calling OpenWeather Forecast API: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseWeatherForecast(data);
      } else if (response.statusCode == 429) {
        print('OpenWeather API rate limit exceeded. Please wait 10 minutes.');
        return [];
      } else if (response.statusCode == 401) {
        print('Invalid OpenWeather API key. Please check your configuration.');
        print('Note: New API keys can take 1-2 hours to activate after signup.');
        return [];
      } else {
        print('Weather Forecast API error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting weather forecast: $e');
      return [];
    }
  }

  /// Get workout recommendations based on weather
  static Future<Map<String, dynamic>> getWorkoutRecommendations() async {
    final weather = await getCurrentWeather();
    if (weather == null) {
      return {
        'recommendations': ['Indoor workout recommended'],
        'reason': 'Unable to get weather data',
      };
    }

    List<String> recommendations = [];
    String reason = '';

    final temp = weather['temperature'];
    final condition = weather['condition'];
    final humidity = weather['humidity'];
    final windSpeed = weather['windSpeed'];

    // Temperature-based recommendations
    if (temp < 0) {
      recommendations.addAll([
        'Indoor yoga or pilates',
        'Home strength training',
        'Treadmill running',
      ]);
      reason = 'Very cold weather - indoor activities recommended';
    } else if (temp < 10) {
      recommendations.addAll([
        'Brisk outdoor walking',
        'Light jogging with warm clothes',
        'Indoor cardio workout',
      ]);
      reason = 'Cold weather - light outdoor or indoor activities';
    } else if (temp >= 10 && temp <= 25) {
      recommendations.addAll([
        'Outdoor running',
        'Cycling',
        'Hiking',
        'Outdoor strength training',
      ]);
      reason = 'Perfect weather for outdoor activities';
    } else if (temp > 25 && temp <= 30) {
      recommendations.addAll([
        'Early morning or evening run',
        'Swimming',
        'Water sports',
        'Shaded outdoor activities',
      ]);
      reason = 'Warm weather - prefer cooler times of day';
    } else {
      recommendations.addAll([
        'Indoor air-conditioned gym',
        'Swimming pool activities',
        'Early morning light exercise',
      ]);
      reason = 'Very hot weather - indoor or water activities recommended';
    }

    // Weather condition adjustments
    if (condition.toLowerCase().contains('rain')) {
      recommendations = [
        'Indoor gym workout',
        'Home fitness routine',
        'Mall walking',
        'Indoor rock climbing',
      ];
      reason = 'Rainy weather - indoor activities recommended';
    } else if (condition.toLowerCase().contains('snow')) {
      recommendations = [
        'Skiing or snowboarding',
        'Winter hiking',
        'Indoor warm-up exercises',
        'Hot yoga',
      ];
      reason = 'Snowy weather - winter sports or warm indoor activities';
    }

    // High humidity adjustments
    if (humidity > 80) {
      recommendations.add('Stay hydrated and take frequent breaks');
    }

    return {
      'recommendations': recommendations.take(4).toList(),
      'reason': reason,
      'weatherCondition': condition,
      'temperature': temp,
      'humidity': humidity,
      'windSpeed': windSpeed,
    };
  }

  /// Get current location
  static Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Parse current weather response
  static Map<String, dynamic> _parseCurrentWeather(Map<String, dynamic> data) {
    return {
      'cityName': data['name'],
      'country': data['sys']['country'],
      'temperature': (data['main']['temp'] as num).toDouble(),
      'feelsLike': (data['main']['feels_like'] as num).toDouble(),
      'condition': data['weather'][0]['main'],
      'description': data['weather'][0]['description'],
      'icon': data['weather'][0]['icon'],
      'humidity': data['main']['humidity'],
      'pressure': data['main']['pressure'],
      'windSpeed': (data['wind']?['speed'] ?? 0).toDouble(),
      'windDirection': data['wind']?['deg'] ?? 0,
      'visibility': data['visibility'] ?? 0,
      'cloudiness': data['clouds']['all'],
      'sunrise': DateTime.fromMillisecondsSinceEpoch(data['sys']['sunrise'] * 1000),
      'sunset': DateTime.fromMillisecondsSinceEpoch(data['sys']['sunset'] * 1000),
      'timestamp': DateTime.now(),
    };
  }

  /// Parse weather forecast response
  static List<Map<String, dynamic>> _parseWeatherForecast(Map<String, dynamic> data) {
    List<Map<String, dynamic>> forecast = [];
    
    for (var item in data['list']) {
      forecast.add({
        'dateTime': DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000),
        'temperature': (item['main']['temp'] as num).toDouble(),
        'feelsLike': (item['main']['feels_like'] as num).toDouble(),
        'tempMin': (item['main']['temp_min'] as num).toDouble(),
        'tempMax': (item['main']['temp_max'] as num).toDouble(),
        'condition': item['weather'][0]['main'],
        'description': item['weather'][0]['description'],
        'icon': item['weather'][0]['icon'],
        'humidity': item['main']['humidity'],
        'windSpeed': (item['wind']?['speed'] ?? 0).toDouble(),
        'cloudiness': item['clouds']['all'],
        'precipitationProbability': (item['pop'] * 100).round(),
      });
    }
    
    return forecast;
  }

  /// Get weather icon URL
  static String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  /// Check if it's good weather for outdoor workout
  static bool isGoodWeatherForOutdoor(Map<String, dynamic> weather) {
    final temp = weather['temperature'];
    final condition = weather['condition'].toLowerCase();
    
    // Good temperature range and no precipitation
    return temp >= 5 && temp <= 30 && 
           !condition.contains('rain') && 
           !condition.contains('snow') &&
           !condition.contains('storm');
  }

  /// Get air quality recommendations
  static List<String> getAirQualityRecommendations(Map<String, dynamic> weather) {
    final humidity = weather['humidity'];
    final windSpeed = weather['windSpeed'];
    
    List<String> recommendations = [];
    
    if (humidity > 80) {
      recommendations.add('High humidity - stay hydrated and take breaks');
    }
    
    if (windSpeed > 15) {
      recommendations.add('Windy conditions - be careful with outdoor activities');
    }
    
    return recommendations;
  }

  /// Check if cached weather data is still valid (within 10 minutes)
  static bool _isCacheValid() {
    if (_cachedWeather == null || _lastFetchTime == null) {
      return false;
    }
    
    final timeDifference = DateTime.now().difference(_lastFetchTime!);
    return timeDifference < _cacheTimeout;
  }

  /// Clear weather cache
  static void clearCache() {
    _cachedWeather = null;
    _lastFetchTime = null;
  }

  /// Check if API key is configured
  static bool isApiKeyConfigured() {
    return _apiKey != 'YOUR_OPENWEATHER_API_KEY' && _apiKey.isNotEmpty;
  }

  /// Validate API key format (OpenWeather API keys are 32 characters long)
  static bool isValidApiKey(String apiKey) {
    return apiKey.length == 32 && RegExp(r'^[a-z0-9]+$').hasMatch(apiKey);
  }
}
