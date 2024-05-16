import 'dart:async';
import 'package:flutter/material.dart';
import 'package:light/light.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class LightSensorPage extends StatefulWidget {
  @override
  _LightSensorPageState createState() => _LightSensorPageState();
}

class _LightSensorPageState extends State<LightSensorPage> {
  double _lightIntensity = 0.0;
  late Light _lightSensor;
  late StreamSubscription<int> _lightSubscription;
  double _highLightThreshold = 30000.0;
  double _lowLightThreshold = 5000.0;
  bool _autoAdjustLights = false;
  List<charts.Series<TimeSeriesLight, DateTime>> _seriesLineData = [];
  List<TimeSeriesLight> _data = [];

  @override
  void initState() {
    super.initState();
    _lightSensor = Light();
    _startListeningToLightSensor();
  }

  @override
  void dispose() {
    _lightSubscription.cancel();
    super.dispose();
  }

  void _startListeningToLightSensor() {
    _lightSubscription = _lightSensor.lightSensorStream.listen((int lux) {
      setState(() {
        _lightIntensity = lux.toDouble();
        _data.add(TimeSeriesLight(DateTime.now(), _lightIntensity));
        if (_data.length > 100) {
          _data.removeAt(0);
        }
        _updateSeriesLineData();
      });
      checkAndTriggerActions(_lightIntensity);
      if (_autoAdjustLights) {
        _adjustSmartLights(_lightIntensity);
      }
    });
  }

  void _updateSeriesLineData() {
    _seriesLineData = [
      charts.Series<TimeSeriesLight, DateTime>(
        id: 'Light Intensity',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TimeSeriesLight light, _) => light.time,
        measureFn: (TimeSeriesLight light, _) => light.intensity,
        data: _data,
      ),
    ];
  }

  void checkAndTriggerActions(double lightIntensity) {
    if (lightIntensity > _highLightThreshold) {
      _showNotification('High Light Intensity', 'Ambient light level is very high.');
    } else if (lightIntensity < _lowLightThreshold) {
      _showNotification('Low Light Intensity', 'Ambient light level is very low.');
    }
  }

  void _adjustSmartLights(double lightIntensity) {
    print('Adjusting smart lights based on light intensity: $lightIntensity');
  }

  void _showNotification(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double glowOpacity = _lightIntensity / 40000;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.hintColor,
        title: Text(
          'Light Sensor',
          style: TextStyle(color: theme.primaryColor),
        ),
        iconTheme: IconThemeData(
          color: theme.primaryColor,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              _showSettingsDialog();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade800],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(glowOpacity),
                      blurRadius: 30,
                      spreadRadius: 30,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'lib/assets/lll.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Light Intensity: ${_lightIntensity.toStringAsFixed(2)} lx',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Container(
                height: 200,
                padding: EdgeInsets.all(20),
                child: charts.TimeSeriesChart(
                  _seriesLineData,
                  animate: true,
                ),
              ),
              SizedBox(height: 20),
              SwitchListTile(
                title: Text(
                  'Auto-Adjust Smart Lights',
                  style: TextStyle(color: Colors.white),
                ),
                value: _autoAdjustLights,
                onChanged: (bool value) {
                  setState(() {
                    _autoAdjustLights = value;
                  });
                },
                activeColor: Colors.blue.shade100,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double tempHighThreshold = _highLightThreshold;
        double tempLowThreshold = _lowLightThreshold;

        return AlertDialog(
          title: Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Set High Light Threshold (lx):'),
              Slider(
                value: tempHighThreshold,
                min: 10000,
                max: 60000,
                divisions: 50,
                label: tempHighThreshold.toStringAsFixed(0),
                onChanged: (value) {
                  setState(() {
                    tempHighThreshold = value;
                  });
                },
              ),
              Text('Set Low Light Threshold (lx):'),
              Slider(
                value: tempLowThreshold,
                min: 0,
                max: 20000,
                divisions: 20,
                label: tempLowThreshold.toStringAsFixed(0),
                onChanged: (value) {
                  setState(() {
                    tempLowThreshold = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _highLightThreshold = tempHighThreshold;
                  _lowLightThreshold = tempLowThreshold;
                });
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class TimeSeriesLight {
  final DateTime time;
  final double intensity;

  TimeSeriesLight(this.time, this.intensity);
}
