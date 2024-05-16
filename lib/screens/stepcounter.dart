import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:charts_flutter/flutter.dart' as charts;

// Global notification initialization
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() {
  runApp(MaterialApp(home: StepCounterPage()));
  initializeNotifications();
}

// Function to initialize notifications
void initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

class StepCounterPage extends StatefulWidget {
  @override
  _StepCounterPageState createState() => _StepCounterPageState();
}

class _StepCounterPageState extends State<StepCounterPage> {
  int _stepCount = 0;
  int _stepGoal = 10000; // Default step goal
  bool _isCounting = false;
  bool _notificationShown = false;
  bool _motionDetected = false; // Flag to track motion detection
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;

  List<ChartData> _data = [];
  late Timer _chartUpdateTimer;

  @override
  void initState() {
    super.initState();
    _chartUpdateTimer = Timer.periodic(Duration(seconds: 1), _updateChartData);
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    _chartUpdateTimer.cancel();
    super.dispose();
  }

  void _startListeningToAccelerometer() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      double accelerationMagnitude = _calculateMagnitude(event.x, event.y, event.z);
      if (accelerationMagnitude > 12.0) {
        if (_isCounting) {
          setState(() {
            _stepCount++;
          });
          if (_stepCount >= _stepGoal) {
            _triggerGoalNotification();
          }
        }
        _triggerMotionNotification();
      }
    });
  }

  double _calculateMagnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }

  void _triggerGoalNotification() async {
    if (!_notificationShown) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'Goal_channel',
        'Goal Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        0,
        'Goal Reached!',
        'You have reached your step goal of $_stepGoal steps!',
        platformChannelSpecifics,
      );
      _notificationShown = true;
    }
  }

  void _triggerMotionNotification() async {
    if (!_motionDetected) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'Motion_channel',
        'Motion Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        1,
        'Motion Detected!',
        'Unexpected movement detected. Please check.',
        platformChannelSpecifics,
      );
      _motionDetected = true;
      Timer(Duration(minutes: 1), () {
        _motionDetected = false; // Reset the motion detection after 1 minute
      });
    }
  }

  void _toggleStepCounting() {
    setState(() {
      if (_isCounting) {
        _accelerometerSubscription.cancel();
      } else {
        _startListeningToAccelerometer();
      }
      _isCounting = !_isCounting;
    });
  }

  void _resetStepCount() {
    setState(() {
      _stepCount = 0;
      _notificationShown = false;
      _data.clear();
    });
  }

  void _updateChartData(Timer timer) {
    setState(() {
      _data.add(ChartData(DateTime.now(), _stepCount.toDouble()));
      if (_data.length > 10) {
        _data.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = _stepCount / _stepGoal;
    return Scaffold(
      appBar: AppBar(
        title: Text('Step Counter'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetStepCount,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Color.fromARGB(255, 170, 171, 171)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '$_stepCount',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'steps',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Goal: $_stepGoal',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Completed: ${(progress * 100).toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.white),
                        Text('291 Kcal', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.location_on, color: Colors.white),
                        Text('5.90 Km', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.timer, color: Colors.white),
                        Text('2h 11m', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  onPressed: _toggleStepCounting,
                  child: Text(
                    _isCounting ? 'Stop' : 'Start',
                    style: TextStyle(fontSize: 24, color: Colors.blue),
                  ),
                ),
                SizedBox(height: 40),
                SizedBox(
                  height: 200,
                  child: charts.TimeSeriesChart(
                    _createSeriesData(),
                    animate: true,
                    dateTimeFactory: const charts.LocalDateTimeFactory(),
                    primaryMeasureAxis: charts.NumericAxisSpec(
                      renderSpec: charts.GridlineRendererSpec(
                        labelStyle: charts.TextStyleSpec(
                          color: charts.MaterialPalette.white,
                        ),
                        lineStyle: charts.LineStyleSpec(
                          color: charts.MaterialPalette.white,
                        ),
                      ),
                    ),
                    domainAxis: charts.DateTimeAxisSpec(
                      renderSpec: charts.SmallTickRendererSpec(
                        labelStyle: charts.TextStyleSpec(
                          color: charts.MaterialPalette.white,
                        ),
                        lineStyle: charts.LineStyleSpec(
                          color: charts.MaterialPalette.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<charts.Series<ChartData, DateTime>> _createSeriesData() {
    return [
      charts.Series<ChartData, DateTime>(
        id: 'Steps',
        colorFn: (_, __) => charts.MaterialPalette.white,
        domainFn: (ChartData data, _) => data.time,
        measureFn: (ChartData data, _) => data.value,
        data: _data,
      ),
    ];
  }
}

class ChartData {
  final DateTime time;
  final double value;

  ChartData(this.time, this.value);
}
