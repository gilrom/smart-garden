import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';
import 'reading.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import 'package:provider/provider.dart';
import "recommendation_screen.dart";

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
  var veryLowColor = Color.fromRGBO(255, 140, 0, 0.947);
  @override
  Widget build(BuildContext context) {
    var timeFormat = DateFormat.Hms();
    if (lastReading == null) {
      return const Center(child: Text('No Data...'));
    }
    DateTime now = DateTime.now();
    var statusCard, tempratureCard,humidityCard, moistureCard, lightCard;
    print("send to screen: ${sendInfoToDatabaseValue}");
    if(now.difference(lastReading!.timestamp!).inSeconds <  sendInfoToDatabaseValue + 5){
      online = true;
      statusCard = Card(
          child: ListTile(
            leading: Icon(Icons.power_settings_new),
            title: Text("Device is online"),
            subtitle: Text("Getting readings every ${sendInfoToDatabaseValue} seconds")));
    }
    else{
      online = false;
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
        );
    }
    //ground moisture status
    double moisture = double.parse(lastReading!.moisture!);
    print("${moisture}");
    if(moisture > 50){
      moistureCard = Card(
          child: ListTile(
            leading: Icon(Icons.water_drop_rounded),
            title: Text("Bad value"),
            subtitle: Text("Error in ground moisture"),
          ),
          color: errorColor,
        );
    }
    //very low moist
    else if(moisture < (dryGroundValue+lowMoistValue) / 2){
      moistureCard = Card(
          child: ListTile(
            leading: Icon(Icons.water_drop_rounded),
            title: Text("${moisture}%"),
            subtitle: Text("Moisture is very low"),
          ),
          color: veryLowColor,
        );
    }
    else if((moisture >= (dryGroundValue+lowMoistValue) / 2) && moisture <= lowMoistValue){
      moistureCard = Card(
          child: ListTile(
            leading: Icon(Icons.water_drop_rounded),
            title: Text("${moisture}%"),
            subtitle: Text("Moisture is a bit low"),
          ),
          color: lowColor,
        );
    }
    else if(moisture < highMoistValue){
      moistureCard = Card(
          child: ListTile(
            leading: Icon(Icons.water_drop_rounded),
            title: Text("${moisture}%"),
            subtitle: Text("Moisture level is good"),
          ),
          color: goodColor,
        );
    }
    else{
      moistureCard = Card(
          child: ListTile(
            leading: Icon(Icons.water_drop_rounded),
            title: Text("${moisture}%"),
            subtitle: Text("Moisture level is very high"),
          ),
          color: veryHighColor,
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
        ),
        Card(
          child: ListTile(
            title: Text("${timeFormat.format(lastReading!.timestamp!)}"),
            subtitle: Text("Reading Time"),
          ),
        ),
        Card(child: CustomButton(onPressed: (){setState(() {});}, label: "Refresh"))
      ],
    );
}

  @override
  void initState() {
    super.initState();
    _listenToReadings();
    _listenToSettings();
    _listenToGroundSettings();
  }

  void _listenToReadings() {
    databaseReference.child(readingsPath).onChildAdded.listen((DatabaseEvent event){
      setState(() {
        print("got new reading!");
        lastReading = ReadingData.fromJson(event.snapshot);
        });
        // Notify listeners of the state change
        Provider.of<MyHomeScreenNotifier>(context, listen: false).notify();
      });
  }
  void _listenToSettings() {
    databaseReference.child(settingsPath).onValue.listen((DatabaseEvent event){
      setState(() {
        print("got new settings reading!");
        Map fields = event.snapshot.value as Map;
        displayTimeoutValue = fields['display time out'];
        sendInfoToDatabaseValue = fields['send information to database'];
        // Provider.of<SettingsNotifier>(context, listen: false).notify();
        });
    });
  }
  void _listenToGroundSettings() {
    databaseReference.child(groundSettingsPath).onValue.listen((DatabaseEvent event){
      setState(() {
        print("got new recommendation reading!");
        Map fields = event.snapshot.value as Map;
        highMoistValue = fields['high_moist'];
        lowMoistValue = fields['low_moist'];
        dryGroundValue = fields['dry_value'];
        // Provider.of<GroundSettingsNotifier>(context, listen: false).notify();
        });
    });
  }
}

// Create a notifier class
class MyHomeScreenNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}
// class GroundSettingsNotifier extends ChangeNotifier {
//   void notify() {
//     notifyListeners();
//   }
// }
// class SettingsNotifier extends ChangeNotifier {
//   void notify() {
//     notifyListeners();
//   }
// }