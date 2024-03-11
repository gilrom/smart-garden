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
          DateTime startOfLastHour = DateTime(now.year, now.month, now.day, now.hour-1);
          _getReadings(startOfLastHour);
          break;
        case ChartDisplayOption.Day:
          _intervalType = DateTimeIntervalType.hours;
          _dateFormat = DateFormat.Hm();
          DateTime startOfLastDay = DateTime(now.year, now.month, now.day - 1);
          _getReadings(startOfLastDay);
          break;
        case ChartDisplayOption.Week:
          _intervalType = DateTimeIntervalType.days;
          _dateFormat = DateFormat("d/M HH:mm");
          DateTime startOfLastWeek = DateTime(now.year, now.month, now.day - 7);
          _getReadings(startOfLastWeek);
          break;
      }
    });
  }

  void _getReadings(DateTime startTime)async {
    Query query = databaseReference.child(readingsPath).orderByKey().startAt((startTime.millisecondsSinceEpoch/1000).toString());
    final event = await query.once();
    final data = event.snapshot.value as Map?;
    if(data == null){
      return; //no data
    }
    _tempData = data.entries.map((entry) {
      DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(entry.key) * 1000);
      double temperature = double.parse(entry.value['temperature']);
      return ChartSampleData(x: timestamp, y: temperature, text: "$temperature%");
    }).toList();
    _humidityData = data.entries.map((entry) {
      DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(entry.key) * 1000);
      double temperature = double.parse(entry.value['humidity']);
      return ChartSampleData(x: timestamp, y: temperature, text: "$temperature%");
    }).toList();
    _moistureData = data.entries.map((entry) {
      DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(entry.key) * 1000);
      double temperature = double.parse(entry.value['moisture']);
      return ChartSampleData(x: timestamp, y: temperature, text: "$temperature°C");
    }).toList();
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
                  xValueMapper: (ChartSampleData sample, _) => sample.x,
                  yValueMapper: (ChartSampleData sample, _) => sample.y,
                  name: "Temperature (°C)",
                ),
                LineSeries<ChartSampleData, DateTime>(
                  dataSource: _humidityData,
                  xValueMapper: (ChartSampleData sample, _) => sample.x,
                  yValueMapper: (ChartSampleData sample, _) => sample.y,
                  name: "Humidity (%)",
                ),
                LineSeries<ChartSampleData, DateTime>(
                  dataSource: _moistureData,
                  xValueMapper: (ChartSampleData sample, _) => sample.x,
                  yValueMapper: (ChartSampleData sample, _) => sample.y,
                  name: "Ground moisture (%)",
                ),
              ],
              trackballBehavior: TrackballBehavior(
                enable: true,
                activationMode: ActivationMode.singleTap,
                tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
                // builder: (BuildContext context, TrackballDetails trackballDetails){
                //   // final String seriesName = trackballDetails.series!.name!;
                //   // final String yAxisFormat = seriesName == 'Temperature' ? '°C' : '%';
                //   print(trackballDetails.groupingModeInfo!.currentPointIndices);
                //   print(trackballDetails.groupingModeInfo!.visibleSeriesList.first.dataSource[20].x);
                //   return Container(
                //     child: Text("Hello"),
                //     decoration: BoxDecoration(
                //       color: Theme.of(context).colorScheme.secondaryContainer,
                //       borderRadius: const BorderRadius.all(Radius.circular(6.0)),
                //     ),
                //   );
                // }
              ),
              legend: const Legend(isVisible: true, position: LegendPosition.bottom),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartSampleData {
  ChartSampleData({required this.x, required this.y, required this.text});

  final DateTime x;
  final double y;
  final String text;
}

enum ChartDisplayOption { Hour, Day, Week }
<<<<<<< HEAD


=======
>>>>>>> Gil
