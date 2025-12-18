// main.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'theme.dart';
import 'models.dart';
import 'storage_service.dart';
import 'places_screen.dart';
import 'logs_screen.dart';
import 'stats_screen.dart';
import 'summary_service.dart';

// Notifications 
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
// main function
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Notification channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'stayput_channel',
    'StayPut Tracking',
    description: 'Shows location tracking updates',
    importance: Importance.high,
    playSound: true,
  );

  final androidPlugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(channel);

  // Notification init
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  await _initializeBackgroundService();

  runApp(const StayPutApp());
}

// Background Service
Future<void> _initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onBackgroundServiceStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'stayput_channel',
      initialNotificationTitle: 'StayPut Tracking Active',
      initialNotificationContent: 'Logging location...',
      foregroundServiceNotificationId: 1001,
    ),
    iosConfiguration: IosConfiguration(),
  );

  service.startService();
}

@pragma('vm:entry-point')
void _onBackgroundServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'StayPut Tracking Active',
      content: 'Logging location...',
    );
  }

  Timer.periodic(const Duration(seconds: 900), (_) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);

      List<Place> places = await StorageService.getPlaces();
      String placeName = "Other";

      for (var p in places) {
        double distance = Geolocator.distanceBetween(
            pos.latitude, pos.longitude, p.latitude, p.longitude);
        if (distance < 50) {
          placeName = p.name;
          break;
        }
      }

      await StorageService.saveLog(
        ActivityLog(
          timestamp: DateTime.now(),
          activity: 'unknown',
          placeName: placeName,
        ),
      );

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Location Saved',
          content:
              '$placeName (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
        );
      }
    } catch (_) {}
  });
}

class StayPutApp extends StatefulWidget {
  const StayPutApp({super.key});

  @override
  State<StayPutApp> createState() => _StayPutAppState();
}

class _StayPutAppState extends State<StayPutApp> with WidgetsBindingObserver {
  int _index = 0;
  List<Widget> _screens = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initApp() async {
    await SummaryService.runDailySummary();
    _screens = [
      const HomeMapScreen(),
      const PlacesScreen(),
      const LogsScreen(),
      const StatsScreen(),
    ];
    setState(() {});
    _startForegroundNotifications();
  }

  void _startForegroundNotifications() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 900), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best);

        List<Place> places = await StorageService.getPlaces();
        String placeName = "Other";

        for (var p in places) {
          double distance = Geolocator.distanceBetween(
              pos.latitude, pos.longitude, p.latitude, p.longitude);
          if (distance < 50) {
            placeName = p.name;
            break;
          }
        }

        await StorageService.saveLog(
          ActivityLog(
            timestamp: DateTime.now(),
            activity: 'unknown',
            placeName: placeName,
          ),
        );

        flutterLocalNotificationsPlugin.show(
          0,
          'Location Saved',
          '$placeName (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'stayput_channel',
              'StayPut Tracking',
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
            ),
          ),
        );
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_screens.isEmpty) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        extendBody: true, // required for transparent nav bar effect
        body: _screens[_index],

        bottomNavigationBar: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined), label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.place_outlined), label: 'Locations'),
                NavigationDestination(
                    icon: Icon(Icons.article_outlined), label: 'Logs'),
                NavigationDestination(
                    icon: Icon(Icons.bar_chart_outlined), label: 'Stats'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Modernized HomeMapScreen with spacing & M3 look
class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});
  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  LatLng? _loc;
  String _name = "Fetching location...";
  bool _loading = true;
  StreamSubscription<Position>? _stream;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  Future<void> _listen() async {
    _stream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      setState(() {
        _loc = LatLng(pos.latitude, pos.longitude);
        _loading = false;
      });
      _updateName(pos.latitude, pos.longitude);
    });
  }

  Future<void> _updateName(double lat, double lon) async {
    try {
      List<Placemark> p = await placemarkFromCoordinates(lat, lon);
      if (p.isNotEmpty) {
        setState(() {
          _name = "${p.first.name}, ${p.first.locality}, ${p.first.country}";
        });
      }
    } catch (_) {
      setState(() => _name = "Unable to get location name");
    }
  }

  @override
  void dispose() {
    _stream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Home", style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 8),
            Text("You are at $_name",
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),

            // Map
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _loc!,
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=6ccgfo8QL58h665rkzea',
                      userAgentPackageName: 'com.example.stayput7',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _loc!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
