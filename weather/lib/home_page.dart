import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:weather/main.dart';
import 'dart:async';
import 'weather_service.dart';
import 'theme_manager.dart';
import 'weather_background.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _cityController = TextEditingController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  late TabController _tabController;
  late AnimationController _animationController;

  Map<String, dynamic>? currentWeather;
  Map<String, dynamic>? forecastWeather;
  Map<String, dynamic>? airQuality;
  List<String> favoriteCities = [];

  bool isLoading = false;
  bool isListening = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _initSpeech();
    _loadFavoriteCities();
    _getCurrentLocationWeather();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _speechToText.cancel();
    super.dispose();
  }

  void _initSpeech() async {
    await _speechToText.initialize();
    setState(() {});
  }

  void _loadFavoriteCities() async {
    final cities = await _weatherService.getFavoriteCities();
    setState(() {
      favoriteCities = cities;
    });
  }

  void _getCurrentLocationWeather() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final position = await _weatherService.getCurrentLocation();
      final data = await _weatherService.fetchWeatherByLocation(
        position.latitude,
        position.longitude,
      );
      final forecast = await _weatherService.fetchForecastByLocation(
        position.latitude,
        position.longitude,
      );
      final airData = await _weatherService.fetchAirQuality(
        position.latitude,
        position.longitude,
      );

      setState(() {
        currentWeather = data;
        forecastWeather = forecast;
        airQuality = airData;
        isLoading = false;
      });

      // Schedule weather alert check
      _checkForWeatherAlerts();
    } catch (e) {
      setState(() {
        errorMessage = 'Could not get current location: $e';
        isLoading = false;
      });
    }
  }

  void _getWeatherByCity(String city) async {
    if (city.isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await _weatherService.fetchWeather(city);
      final forecast = await _weatherService.fetchForecast(city);
      final airData = await _weatherService.fetchAirQuality(
        data['coord']['lat'],
        data['coord']['lon'],
      );

      setState(() {
        currentWeather = data;
        forecastWeather = forecast;
        airQuality = airData;
        isLoading = false;
      });

      // Schedule weather alert check
      _checkForWeatherAlerts();
    } catch (e) {
      setState(() {
        errorMessage = 'City not found 😞';
        isLoading = false;
        currentWeather = null;
        forecastWeather = null;
        airQuality = null;
      });
    }
  }

  void _listen() async {
    if (!_speechToText.isAvailable) {
      return;
    }

    if (isListening) {
      _speechToText.stop();
      setState(() {
        isListening = false;
      });
      return;
    }

    setState(() {
      isListening = true;
    });

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          _cityController.text = result.recognizedWords;
          _getWeatherByCity(result.recognizedWords);
          setState(() {
            isListening = false;
          });
        }
      },
    );
  }

  void _toggleFavorite() async {
    if (currentWeather == null) return;

    final cityName = currentWeather!['name'];

    if (favoriteCities.contains(cityName)) {
      await _weatherService.removeFavoriteCity(cityName);
      favoriteCities.remove(cityName);
    } else {
      await _weatherService.saveFavoriteCity(cityName);
      favoriteCities.add(cityName);
    }

    setState(() {});
  }

  String _getWeatherBackground() {
    if (currentWeather == null) return 'default';

    return currentWeather!['weather'][0]['main'].toString().toLowerCase();
  }

  void _checkForWeatherAlerts() {
    if (forecastWeather == null) return;

    // Check for extreme weather in the forecast
    final List forecastList = forecastWeather!['list'];

    for (var forecast in forecastList) {
      final temp = forecast['main']['temp'];
      final weatherId = forecast['weather'][0]['id'];

      // Check for extreme conditions
      if (temp > 35 || temp < 0 || weatherId < 300) {
        _showWeatherNotification(forecast);
        break;
      }
    }
  }

  Future<void> _showWeatherNotification(Map<String, dynamic> forecast) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'weather_alerts',
          'Weather Alerts',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final dateTime = DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
    final weatherDesc = forecast['weather'][0]['description'];
    final temp = forecast['main']['temp'].toStringAsFixed(1);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Weather Alert',
      'Upcoming $weatherDesc with temperature $temp°C on ${DateFormat('MMM dd, HH:mm').format(dateTime)}',
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.cloud), text: 'Current Weather'),
            Tab(icon: Icon(Icons.view_week), text: 'Forecast'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCurrentWeatherTab(), _buildForecastTab()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        child: Icon(isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }

  Widget _buildCurrentWeatherTab() {
    if (isLoading) {
      return const Center(child: SpinKitCircle(color: Colors.blue, size: 50.0));
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 18),
        ),
      );
    }

    if (currentWeather == null) {
      return const Center(
        child: Text(
          'No weather data available',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          currentWeather!['name'],
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          '${currentWeather!['main']['temp']}°C',
          style: const TextStyle(fontSize: 48),
        ),
        Text(
          currentWeather!['weather'][0]['description'],
          style: const TextStyle(fontSize: 18),
        ),
        IconButton(
          icon: Icon(
            favoriteCities.contains(currentWeather!['name'])
                ? Icons.favorite
                : Icons.favorite_border,
          ),
          onPressed: _toggleFavorite,
        ),
      ],
    );
  }

  Widget _buildForecastTab() {
    if (isLoading) {
      return const Center(child: SpinKitCircle(color: Colors.blue, size: 50.0));
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 18),
        ),
      );
    }

    if (forecastWeather == null) {
      return const Center(
        child: Text(
          'No forecast data available',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    final List forecastList = forecastWeather!['list'];

    return ListView.builder(
      itemCount: forecastList.length,
      itemBuilder: (context, index) {
        final forecast = forecastList[index];
        final dateTime = DateTime.fromMillisecondsSinceEpoch(
          forecast['dt'] * 1000,
        );
        final temp = forecast['main']['temp'];
        final description = forecast['weather'][0]['description'];

        return ListTile(
          leading: Text(
            DateFormat('EEE, MMM d').format(dateTime),
            style: const TextStyle(fontSize: 16),
          ),
          title: Text('$temp°C', style: const TextStyle(fontSize: 18)),
          subtitle: Text(description),
        );
      },
    );
  }
}
