import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'reading.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import 'package:provider/provider.dart';
import 'main.dart';

ReadingData? lastReading;
bool online = false;

class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});
  @override
  _MyHomeScreenState createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {

  var errorColor = const Color.fromRGBO(255, 0, 0, 0.7);
  //ground moisture colors
  var veryHighColor = const Color.fromRGBO(0, 0, 255, 0.7);
  var goodColor = const Color.fromRGBO(0, 255, 0, 0.7);
  var lowColor = const Color.fromRGBO(255, 255, 0, 0.7);
  var veryLowColor = const Color.fromRGBO(255, 140, 0, 0.947);
  @override
  Widget build(BuildContext context) {
    var timeFormat = DateFormat.Hms();
    if (lastReading == null) {
      return const Center(child: Text('No Data...'));
    }
    DateTime now = DateTime.now();
    Card statusCard, tempratureCard,humidityCard, moistureCard, lightCard;
    if(now.difference(lastReading!.timestamp!).inSeconds <  sendInfoToDatabaseValue + 5){
      online = true;
      statusCard = Card(
          child: ListTile(
            leading: const Icon(Icons.power_settings_new),
            title: const Text("Device is online"),
            subtitle: Text("Getting readings every ${sendInfoToDatabaseValue.round()} seconds")));
    }
    else{
      online = false;
      statusCard = Card(
          color: errorColor,
          child: ListTile(
            leading: const Icon(Icons.power_settings_new),
            title: const Text("Device is offline"),
            subtitle: Text("No reading for more than ${sendInfoToDatabaseValue.round()} seconds")),
      );
    }
    //temprature status
    if(lastReading!.temp == "nan"){
      tempratureCard = Card(
        color: errorColor,
        child: const ListTile(
        leading: Icon(Icons.thermostat),
        title: Text("Bad value"),
        subtitle: Text("Error in temprature sensor"),
        ),
        );
      humidityCard = Card(
          color: errorColor,
          child: const ListTile(
            leading: Icon(Icons.percent),
            title: Text("Bad value"),
            subtitle: Text("Error in temprature sensor"),
          ),
        );
    }
    else{
      tempratureCard = Card(
          child: ListTile(
            leading: const Icon(Icons.thermostat),
            title: Text("${lastReading!.temp}°C"),
            subtitle: const Text("Temprature"),
          ),
        );
      humidityCard = Card(
          child: ListTile(
            leading: const Icon(Icons.percent),
            title: Text("${lastReading!.humidity!}%"),
            subtitle: const Text("Humidity"),
          ),
        );
    }
    //ground moisture status
    double moisture = double.parse(lastReading!.moisture!);
    print("$moisture");
    if(moisture > 50){
      moistureCard = Card(
          color: errorColor,
          child: const ListTile(
            leading: Icon(Icons.water_drop_rounded),
            title: Text("Bad value"),
            subtitle: Text("Error in ground moisture"),
          ),
        );
    }
    //very low moist
    else if(moisture < (dryGroundValue+lowMoistValue) / 2){
      moistureCard = Card(
          color: veryLowColor,
          child: ListTile(
            leading: const Icon(Icons.water_drop_rounded),
            title: Text("$moisture%"),
            subtitle: const Text("Moisture is very low"),
          ),
        );
    }
    else if((moisture >= (dryGroundValue+lowMoistValue) / 2) && moisture <= lowMoistValue){
      moistureCard = Card(
          color: lowColor,
          child: ListTile(
            leading: const Icon(Icons.water_drop_rounded),
            title: Text("$moisture%"),
            subtitle: const Text("Moisture is a bit low"),
          ),
        );
    }
    else if(moisture < highMoistValue){
      moistureCard = Card(
          color: goodColor,
          child: ListTile(
            leading: const Icon(Icons.water_drop_rounded),
            title: Text("$moisture%"),
            subtitle: const Text("Moisture level is good"),
          ),
        );
    }
    else{
      moistureCard = Card(
          color: veryHighColor,
          child: ListTile(
            leading: const Icon(Icons.water_drop_rounded),
            title: Text("$moisture%"),
            subtitle: const Text("Moisture level is very high"),
          ),
        );
    }
    if(lastReading!.light! == "100"){
      lightCard = Card(
          color: errorColor,
          child: const ListTile(
            leading: Icon(Icons.light_mode),
            title: Text("Bad reading"),
            subtitle: Text("Error in light sensor"),
          ),
        );
    }
    else{
      lightCard = Card(
          child: ListTile(
            leading: const Icon(Icons.light_mode),
            title: Text("${lastReading!.light!}%"),
            subtitle: const Text("Light Level"),
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
            leading: const Icon(Icons.access_time),
            title: Text(timeFormat.format(lastReading!.timestamp!)),
            subtitle: const Text("Reading Time"),
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
    databaseReference.child(readingsPath).orderByKey().limitToLast(1).onChildAdded.listen((DatabaseEvent event){
      lastReading = ReadingData.fromJson(event.snapshot);
      Provider.of<MyHomeScreenNotifier>(context, listen: false).notify();
      setState((){});
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