import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';
import 'reading.dart';
import 'package:intl/intl.dart';


class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});
  @override
  _MyHomeScreenState createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {
  ReadingData? lastReading;


  @override
  Widget build(BuildContext context) {
    var timeFormat = DateFormat.Hms();
    if (lastReading == null) {
      return const Center(child: Text('No Data...'));
    }
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text('Last Readings'),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.thermostat),
            title: Text("${lastReading!.temp}°C"),
            subtitle: Text("Temprature"),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.percent),
            title: Text("${lastReading!.humidity!}%"),
            subtitle: Text("Humidity"),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.water_drop_rounded),
            title: Text("${lastReading!.moisture!}%"),
            subtitle: Text("Ground Moisture"),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.light_mode),
            title: Text("${lastReading!.light!}%"),
            subtitle: Text("Light Level"),
          ),
        ),
        Card(
          child: ListTile(
            title: Text("${timeFormat.format(lastReading!.timestamp!)}"),
            subtitle: Text("Reading Time"),
          ),
        ),
      ],
    );
}

  @override
  void initState() {
    super.initState();
    _listenToFirebase();
  }

  void _listenToFirebase() {
    databaseReference.child(readingsPath).onChildAdded.listen((DatabaseEvent event){
      setState(() {
        lastReading = ReadingData.fromJson(event.snapshot);
        });
      });
  }
}
