import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Location _locationController = Location();
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng _kigaliCenter = LatLng(-1.9441, 30.0619);
  Map<PolylineId, Polyline> polylines = {};
  Map<PolygonId, Polygon> _polygons = {};
  StreamSubscription<LocationData>? _locationSubscription;
  bool _notificationSentOutSide = false;
  bool _notificationSentInSide = false;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _createGeofence();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _createGeofence() {
    List<LatLng> kigaliBoundaries = [
      LatLng(-1.9740, 30.0274),
      LatLng(-1.9740, 30.1300),
      LatLng(-1.8980, 30.1300),
      LatLng(-1.8980, 30.0274),
    ];
    PolygonId polygonId = PolygonId('kigali');
    Polygon polygon = Polygon(
      polygonId: polygonId,
      points: kigaliBoundaries,
      strokeWidth: 2,
      strokeColor: Colors.blue,
      fillColor: Colors.blue.withOpacity(0.3),
    );
    setState(() {
      _polygons[polygonId] = polygon;
    });
  }

  void _startLocationUpdates() async {
    bool serviceEnabled = await _locationController.requestService();
    if (!serviceEnabled) return;
    PermissionStatus permissionGranted = await _locationController.requestPermission();
    if (permissionGranted != PermissionStatus.granted) return;

    _locationSubscription = _locationController.onLocationChanged.listen((LocationData currentLocation) {
      LatLng currentLatLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
      bool insideGeofence = _isLocationInsideGeofence(currentLatLng);
      if (insideGeofence && !_notificationSentInSide) {
        _triggerNotification('Inside Geofence', 'You are within the geographical boundaries of Kigali.');
        _notificationSentInSide = true;
        _notificationSentOutSide = false;
      } else if (!insideGeofence && !_notificationSentOutSide) {
        _triggerNotification('Outside Geofence', 'You have exited the geographical boundaries of Kigali.');
        _notificationSentOutSide = true;
        _notificationSentInSide = false;
      }
    });
  }

  bool _isLocationInsideGeofence(LatLng location) {
    return _polygons.values.any((polygon) => _containsLocation(location, polygon.points));
  }

  bool _containsLocation(LatLng point, List<LatLng> vertices) {
    int intersectCount = 0;
    for (int j = 0; j < vertices.length; j++) {
      LatLng vertex1 = vertices[j];
      LatLng vertex2 = vertices[(j + 1) % vertices.length];
      if ((vertex1.longitude < point.longitude && vertex2.longitude >= point.longitude) ||
          (vertex2.longitude < point.longitude && vertex1.longitude >= point.longitude)) {
        if (vertex1.latitude + (point.longitude - vertex1.longitude) / (vertex2.longitude - vertex1.longitude) * (vertex2.latitude - vertex1.latitude) < point.latitude) {
          intersectCount++;
        }
      }
    }
    return intersectCount % 2 != 0; // odd = inside, even = outside
  }

  void _triggerNotification(String title, String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'geofence_channel',
      'Geofence Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(0, title, message, platformDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kigali Geofence Monitoring'),
      ),
      body: GoogleMap(
        onMapCreated: _mapController.complete,
        initialCameraPosition: CameraPosition(target: _kigaliCenter, zoom: 12),
        polygons: Set<Polygon>.of(_polygons.values),
      ),
    );
  }
}
