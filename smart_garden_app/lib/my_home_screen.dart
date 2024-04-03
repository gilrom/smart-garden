import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';
import 'reading.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import 'package:provider/provider.dart';

ReadingData? lastReading;
bool online = false;

class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});
  @override
  _MyHomeScreenState createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {

  var errorColor = Color.fromRGBO(255, 0, 0, 0.7);
  //ground moisture colors
  var veryHighColor = Color.fromRGBO(0, 0, 255, 0.7);
  var goodColor = Color.fromRGBO(0, 255, 0, 0.7);
  var lowColor = Color.fromRGBO(255, 255, 0, 0.7);
  var veryLowColor = Color.fromRGBO(255, 165, 0, 0.7);
  @override
  Widget build(BuildContext context) {
    var timeFormat = DateFormat.Hms();
    if (lastReading == null) {
      return const Center(child: Text('No Data...'));
    }
    DateTime now = DateTime.now();
    var statusCard, tempratureCard,humidityCard, moistureCard, lightCard;
    if(now.difference(lastReading!.timestamp!).inSeconds <  sendInfoToDatabaseValue + 20){
      online = true;
      statusCard = Card(
          child: ListTile(
            leading: Icon(Icons.power_settings_new),
            title: Text("Device is online"),)
          );
    }
    else{
      online = false;
      statusCard = Card(
          child: ListTile(
            leading: Icon(Icons.power_settings_new),
            title: Text("Device is offline"),
            subtitle: Text("No reading for more than ${sendInfoToDatabaseValue} seconds")),
            color: errorColor,
      );
    }
    //temprature status
    if(lastReading!.temp == "nan"){
      tempratureCard = Card(
        child: ListTile(
        leading: Icon(Icons.thermostat),
        title: Text("Bad value"),
        subtitle: Text("Error in temprature sensor"),
        ),
        color: errorColor,
        );
      humidityCard = Card(
          child: ListTile(
            leading: Icon(Icons.percent),
            title: Text("Bad value"),
            subtitle: Text("Error in temprature sensor"),
          ),
          color: errorColor,
        );
    }
    else{
      tempratureCard = Card(
          child: ListTile(
            leading: Icon(Icons.thermostat),
            title: Text("${lastReading!.temp}°C"),
            subtitle: Text("Temprature"),
          ),
        );
      humidityCard = Card(
          child: ListTile(
            leading: Icon(Icons.percent),
            title: Text("${lastReading!.humidity!}%"),
            subtitle: Text("Humidity"),
          ),
        );
    }
    //ground moisture status
    if(int.parse(lastReading!.moisture!) > 80){
      moistureCard = Card(
          child: ListTile(
            leading: Icon(Icons.water_drop_rounded),
            title: Text("Bad value"),
            subtitle: Text("Error in ground moisture"),
          ),
          color: errorColor,
        );
    }
    else{
      moistureCard = Card(
          child: ListTile(
            leading: Icon(Icons.water_drop_rounded),
            title: Text("${lastReading!.moisture!}%"),
            subtitle: Text("Ground Moisture"),
          ),
        );
    }
    if(lastReading!.light! == "100"){
      lightCard = Card(
          child: ListTile(
            leading: Icon(Icons.light_mode),
            title: Text("Bad reading"),
            subtitle: Text("Error in light sensor"),
          ),
          color: errorColor,
        );
    }
    else{
      lightCard = Card(
          child: ListTile(
            leading: Icon(Icons.light_mode),
            title: Text("${lastReading!.light!}%"),
            subtitle: Text("Light Level"),
          ),
        );
    }
    return ListView(
      children: [
        statusCard,
        tempratureCard,
        humidityCard,
        moistureCard,
        lightCard,
        Card(
          child: ListTile(
            leading: Icon(Icons.access_time),
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
        // Notify listeners of the state change
        Provider.of<MyHomeScreenNotifier>(context, listen: false).notify();
      });
  }
}

// Create a notifier class
class MyHomeScreenNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}