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
  double? _interval = null;

  @override
  void initState() {
    DateTime now = DateTime.now();
    DateTime startTime = now.subtract(const Duration(hours: 1));
    super.initState();
    _getReadings(startTime);
  }

  void onTimeRangeChanged(ChartDisplayOption newValue) {
    _tempData.clear(); // Clear existing data
    _moistureData.clear();
    _humidityData.clear();
    _lightData.clear();
    DateTime now = DateTime.now();
    DateTime startTime = now.subtract(const Duration(hours: 1));
    _displayOption = newValue;
    setState(() {
      switch (_displayOption) {
        case ChartDisplayOption.Hour:
          _dateFormat = DateFormat.Hm();
          _intervalType = DateTimeIntervalType.minutes;
            startTime = now.subtract(const Duration(hours: 1));
          break;
        case ChartDisplayOption.Day:
          _intervalType = DateTimeIntervalType.minutes;
          _interval = 30.0;
          _dateFormat = DateFormat.Hm();
          startTime = now.subtract(const Duration(days: 1));
          break;
        case ChartDisplayOption.Week:
          _intervalType = DateTimeIntervalType.hours;
          _interval = 10.0;
          _dateFormat = DateFormat("d/M HH:mm");
          startTime = now.subtract(const Duration(days: 7));
          break;
      }
    });
    _getReadings(startTime);
  }

  void _getReadings(DateTime startTime) {
    int timeIndex = (startTime.millisecondsSinceEpoch/1000).floor();
    Query query = databaseReference.child(readingsPath).orderByKey().startAt(timeIndex.toString());
    query.onValue.listen((DatabaseEvent event){
      setState(() {
        if(_tempData.isEmpty){
          for(var data in event.snapshot.children){
            var value  = data.value as Map;
            DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(data.key!) * 1000);
            if(value ['temperature'] == "nan"){
              _tempData.add(ChartSampleData(x: timestamp, y: null));
            }
            else{
              double temperature = double.parse(value['temperature']);
              _tempData.add(ChartSampleData(x: timestamp, y: temperature));
            }
            if(value ['humidity'] == "nan"){
              _humidityData.add(ChartSampleData(x: timestamp, y: null));
            }
            else{
              double humidity = double.parse(value['humidity']);
              _humidityData.add(ChartSampleData(x: timestamp, y: humidity));
            }
            double moisture = double.parse(value['moisture']);
            _moistureData.add(ChartSampleData(x: timestamp, y: moisture));
            double light = double.parse(value['light']);
            _lightData.add(ChartSampleData(x: timestamp, y: light));
          }
        }
        else{
          var data = event.snapshot.children.last;
          var value  = data.value as Map;
          DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(data.key!) * 1000);
          if(value ['temperature'] == "nan"){
            _tempData.add(ChartSampleData(x: timestamp, y: null));
          }
          else{
            double temperature = double.parse(value['temperature']);
            _tempData.add(ChartSampleData(x: timestamp, y: temperature));
          }
          if(value ['humidity'] == "nan"){
            _humidityData.add(ChartSampleData(x: timestamp, y: null));
          }
          else{
            double humidity = double.parse(value['humidity']);
            _humidityData.add(ChartSampleData(x: timestamp, y: humidity));
          }
          double moisture = double.parse(value['moisture']);
          _moistureData.add(ChartSampleData(x: timestamp, y: moisture));
          double light = double.parse(value['light']);
          _lightData.add(ChartSampleData(x: timestamp, y: light));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(13.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed:(){onTimeRangeChanged(ChartDisplayOption.Hour);} ,
                  style: ElevatedButton.styleFrom(backgroundColor: _displayOption == ChartDisplayOption.Hour ? Theme.of(context).highlightColor : Theme.of(context).cardColor),
                  child: const Text('Hour')
                ),
                ElevatedButton(
                  onPressed:(){onTimeRangeChanged(ChartDisplayOption.Day);},
                  style: ElevatedButton.styleFrom(backgroundColor: _displayOption == ChartDisplayOption.Day ? Theme.of(context).highlightColor : Theme.of(context).cardColor),
                  child: const Text('Day')
                ),
                ElevatedButton(
                  onPressed:(){onTimeRangeChanged(ChartDisplayOption.Week);},
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
                interval: _interval,
                // autoScrollingDelta: ,
                // autoScrollingDeltaType: _intervalType,
              ),
              // zoomPanBehavior:ZoomPanBehavior(enablePanning: true),
              series: <CartesianSeries<ChartSampleData, DateTime>>[
                FastLineSeries<ChartSampleData, DateTime>(
                  dataSource: _tempData,
                  color: const Color.fromRGBO(221, 18, 18, 1),
                  xValueMapper: (ChartSampleData sample, _) => sample.x,
                  yValueMapper: (ChartSampleData sample, _) => sample.y,
                  name: "Temperature (°C)",
                  // sortingOrder: SortingOrder.ascending,
                  // // Sorting based on the specified field
                  // sortFieldValueMapper: (ChartSampleData data, _) => data.x
                ),
                FastLineSeries<ChartSampleData, DateTime>(
                  dataSource: _humidityData,
                  color: const Color.fromRGBO(28, 79, 218, 1),
                  xValueMapper: (ChartSampleData sample, _) => sample.x,
                  yValueMapper: (ChartSampleData sample, _) => sample.y,
                  name: "Humidity (%)",
                  // sortingOrder: SortingOrder.ascending,
                  // // Sorting based on the specified field
                  // sortFieldValueMapper: (ChartSampleData data, _) => data.x
                ),
                FastLineSeries<ChartSampleData, DateTime>(
                  dataSource: _moistureData,
                  color: const Color.fromRGBO(107, 84, 21, 1),
                  xValueMapper: (ChartSampleData sample, _) => sample.x,
                  yValueMapper: (ChartSampleData sample, _) => sample.y,
                  name: "Ground moisture (%)",
                  // sortingOrder: SortingOrder.ascending,
                  // // Sorting based on the specified field
                  // sortFieldValueMapper: (ChartSampleData data, _) => data.x
                ),
                FastLineSeries<ChartSampleData, DateTime>(
                  dataSource: _lightData,
                  color: const Color.fromRGBO(18, 163, 49, 1),
                  xValueMapper: (ChartSampleData sample, _) => sample.x,
                  yValueMapper: (ChartSampleData sample, _) => sample.y,
                  name: "Light Level (%)",
                  // sortingOrder: SortingOrder.ascending,
                  // // Sorting based on the specified field
                  // sortFieldValueMapper: (ChartSampleData data, _) => data.x
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
  final double? y;
}

enum ChartDisplayOption { Hour, Day, Week }
