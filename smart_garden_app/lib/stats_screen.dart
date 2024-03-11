import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'main.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<ChartSampleData> _moistureData = [];
  List<ChartSampleData> _tempData = [];
  List<ChartSampleData> _humidityData = [];
  List<ChartSampleData> _lightData = [];
  ChartDisplayOption _displayOption = ChartDisplayOption.Hour;
  DateFormat _dateFormat = DateFormat.Hm();
  var _intervalType = DateTimeIntervalType.minutes;

  @override
  void initState() {
    super.initState();
    _updateChartData();
  }

  void _updateChartData() {
    _moistureData = [];
    _tempData = [];
    _humidityData = [];
    DateTime now = DateTime.now();
    setState(() {
      switch (_displayOption) {
        case ChartDisplayOption.Hour:
          _dateFormat = DateFormat.Hm();
          _intervalType = DateTimeIntervalType.minutes;
          DateTime startOfLastHour = now.subtract(const Duration(hours: 1));
          _getReadings(startOfLastHour);
          break;
        case ChartDisplayOption.Day:
          _intervalType = DateTimeIntervalType.hours;
          _dateFormat = DateFormat.Hm();
          DateTime startOfLastDay = now.subtract(const Duration(days: 1));
          _getReadings(startOfLastDay);
          break;
        case ChartDisplayOption.Week:
          _intervalType = DateTimeIntervalType.days;
          _dateFormat = DateFormat("d/M HH:mm");
          DateTime startOfLastWeek = now.subtract(const Duration(days: 7));
          _getReadings(startOfLastWeek);
          break;
      }
    });
  }

  void _getReadings(DateTime startTime) {
    int timeIndex = (startTime.millisecondsSinceEpoch/1000).floor();
    Query query = databaseReference.child(readingsPath).orderByKey().startAt(timeIndex.toString());
    query.onValue.listen((DatabaseEvent event){
      setState(() {
        print("here");
        final data = event.snapshot.value as Map?;
        if(data == null){
          return; //no data
        }
        _tempData = data.entries.map((entry) {
          DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(entry.key) * 1000);
          double temperature = double.parse(entry.value['temperature']);
          return ChartSampleData(x: timestamp, y: temperature);
        }).toList();
        _humidityData = data.entries.map((entry) {
          DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(entry.key) * 1000);
          double temperature = double.parse(entry.value['humidity']);
          return ChartSampleData(x: timestamp, y: temperature);
        }).toList();
        _moistureData = data.entries.map((entry) {
          DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(entry.key) * 1000);
          double temperature = double.parse(entry.value['moisture']);
          return ChartSampleData(x: timestamp, y: temperature);
        }).toList();
        _lightData = data.entries.map((entry) {
          DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(entry.key) * 1000);
          double light_lvl = double.parse(entry.value['light']);
          return ChartSampleData(x: timestamp, y: light_lvl);
        }).toList();
        });
      });
    // print("ok");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _displayOption = ChartDisplayOption.Hour;
                      _updateChartData();
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _displayOption == ChartDisplayOption.Hour ? Theme.of(context).highlightColor : Theme.of(context).cardColor),
                  child: const Text('Hour')
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _displayOption = ChartDisplayOption.Day;
                      _updateChartData();
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _displayOption == ChartDisplayOption.Day ? Theme.of(context).highlightColor : Theme.of(context).cardColor),
                  child: const Text('Day')
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _displayOption = ChartDisplayOption.Week;
                      _updateChartData();
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _displayOption == ChartDisplayOption.Week ? Theme.of(context).highlightColor : Theme.of(context).cardColor),
                  child: const Text('Week')
                ),
              ],
            ),
          ),
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                intervalType: _intervalType,
                dateFormat: _dateFormat,
              ),
              series: <LineSeries<ChartSampleData, DateTime>>[
                LineSeries<ChartSampleData, DateTime>(
                  dataSource: _tempData,
                  color: Color.fromRGBO(221, 18, 18, 1),
                  xValueMapper: (ChartSampleData sample, _) => sample.x,
                  yValueMapper: (ChartSampleData sample, _) => sample.y,
                  name: "Temperature (°C)",
                ),
                LineSeries<ChartSampleData, DateTime>(
                  dataSource: _humidityData,
                  color: Color.fromRGBO(28, 79, 218, 1),
                  xValueMapper: (ChartSampleData sample, _) => sample.x,
                  yValueMapper: (ChartSampleData sample, _) => sample.y,
                  name: "Humidity (%)",
                ),
                LineSeries<ChartSampleData, DateTime>(
                  dataSource: _moistureData,
                  color: Color.fromRGBO(107, 84, 21, 1),
                  xValueMapper: (ChartSampleData sample, _) => sample.x,
                  yValueMapper: (ChartSampleData sample, _) => sample.y,
                  name: "Ground moisture (%)",
                ),
                LineSeries<ChartSampleData, DateTime>(
                  dataSource: _lightData,
                  color: Color.fromRGBO(18, 163, 49, 1),
                  xValueMapper: (ChartSampleData sample, _) => sample.x,
                  yValueMapper: (ChartSampleData sample, _) => sample.y,
                  name: "Light Level (%)",
                ),
              ],
              trackballBehavior: TrackballBehavior(
                enable: true,
                activationMode: ActivationMode.singleTap,
                tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
              ),
              legend: const Legend(isVisible: true, position: LegendPosition.bottom, isResponsive: true),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartSampleData {
  ChartSampleData({required this.x, required this.y});

  final DateTime x;
  final double y;
}

enum ChartDisplayOption { Hour, Day, Week }
