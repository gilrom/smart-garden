import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';
import 'reading.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';

ReadingData? lastReading;

class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});
  @override
  _MyHomeScreenState createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {


  @override
  Widget build(BuildContext context) {
    var timeFormat = DateFormat.Hms();
    if (lastReading == null) {
      return const Center(child: Text('No Data...'));
    }
    DateTime now = DateTime.now();
    var statusCard;
    if(now.difference(lastReading!.timestamp!).inSeconds <  sendInfoToDatabaseValue + 20){
      statusCard = Card(
          child: ListTile(
            leading: Icon(Icons.power_settings_new),
            title: Text("Device is online"),)
          );
    }
    else{
      statusCard = Card(
          child: ListTile(
            leading: Icon(Icons.power_settings_new),
            title: Text("Device is offline"),
            subtitle: Text("No reading for more than ${sendInfoToDatabaseValue} seconds")),
            color: Color.fromRGBO(220, 27, 27, 0.989),
      );
    }
    return ListView(
      children: [
        statusCard,
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
        print("got new reading!");
        lastReading = ReadingData.fromJson(event.snapshot);
        });
      });
  }
}
