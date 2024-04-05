import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';
import 'my_home_screen.dart';
import 'package:provider/provider.dart';


double lowMoistValue = 0.0; 
double highMoistValue = 0.0; 
double dryGroundValue = 0.0;
const int tuningDelta = 3;

enum Tuning {start, stop }


class GroundSettingsScreen extends StatefulWidget {
  const GroundSettingsScreen({super.key});

  @override
  _GroundSettingsScreenState createState() => _GroundSettingsScreenState();
}

class _GroundSettingsScreenState extends State<GroundSettingsScreen> {
  String groundCondition = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ground moisture calibration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              showInfoDialog();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width - 40, 
              child: CustomButton(
                onPressed: () {
                  if(online){
                    setGroundCondition('Watering the Soil');
                    _updateFirebaseDataForStartTuning(Tuning.start);
                    showSetupDialog();
                  }
                  else{
                    showOfflineDialog();
                  }
                },
                label: 'Watering the Soil',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: MediaQuery.of(context).size.width - 40, 
              child: CustomButton(
                onPressed: () {
                  if(online){
                    setGroundCondition('Dry Ground');
                    _updateFirebaseDataForStartTuning(Tuning.start);
                    showSetupDialogForDry();
                  }
                  else{
                    showOfflineDialog();
                  }
                },
                label: 'Dry Ground',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void setGroundCondition(String condition) {
    setState(() {
      groundCondition = condition;
    });
  }

  void showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Soil Moisture Sensor Setup'),
          content: const Text(
            'Use one of above options for fine tuning of the moisture sensor. Before watering for the first time, use the "Watering the soil" option; it will help us set the boundaries of wet and dry soil to inform you about the need for watering or through too wet soil if necessary. If you still have untouched soil, use the "Dry Ground" option, so we will set a threshold when you need to urgently water the soil if necessary.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void showSetupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Setup Instructions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('You will now begin setting up your sensor. Click "Continue".'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  showInsertSensorDialog();
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      },
    );
  }

  

  void showInsertSensorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Insert Moisture Sensor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Insert the moisture sensor into a slightly dump soil, This will be the mid value for soil moisture, wait a few seconds for stabilization. Click "Next" to continue'),
              const SizedBox(height: 20),
              CircularProgressIndicator(),
              GroundReadingWidget(),
              ElevatedButton(
                onPressed: () {
                  DateTime now = DateTime.now();
                  if(now.difference(lastReading!.timestamp!).inSeconds <  tuningDelta + 3){
                    lowMoistValue = double.parse(lastReading!.moisture!);
                    Navigator.of(context).pop();
                    showWaterSoilDialog();
                  }
                  else{
                    showOfflineDialog();
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Next'),
              ),
            ],
          ),
        );
      },
    );
  }

  void showWaterSoilDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Water the Soil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Now water the soil as much as you can. This value will be a high level for the sensor, wait a few seconds for stabilization. Click finish when ready.'),
            const SizedBox(height: 20),
            CircularProgressIndicator(),
            GroundReadingWidget(),
            ElevatedButton(
              onPressed: () {
                DateTime now = DateTime.now();
                if(now.difference(lastReading!.timestamp!).inSeconds <  tuningDelta + 3){
                  highMoistValue = double.parse(lastReading!.moisture!); 
                  try {
                    _updateFirebaseDataForWatering();
                  }
                  catch(e){
                    showSendingErrorDialog();
                  }
                }
                else{
                  print("here");
                  showOfflineDialog();
                }
                _updateFirebaseDataForStartTuning(Tuning.stop);
                Navigator.of(context).pop();
              },
              child: const Text('Finish'),
            ),
          ],
        ),
      );
    },
  );

  
}
void showSetupDialogForDry() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Setup Instructions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('For this setup, you will need untoched, dry soil. Stick the sensor in the ground and wait a few seconds for stabilization, when clicked "Finish" apllication will read information from sensor, and automaticaly update the dry ground value'),
              const SizedBox(height: 20),
              CircularProgressIndicator(),
              GroundReadingWidget(),
              ElevatedButton(
                onPressed: ()  {
                  DateTime now = DateTime.now();
                  if(now.difference(lastReading!.timestamp!).inSeconds <  tuningDelta + 5){
                    dryGroundValue = double.parse(lastReading!.moisture!);
                    try{
                      _updateFirebaseDataForDry();
                    }
                    catch(e){
                      Navigator.of(context).pop();
                      showSendingErrorDialog();
                    }
                    Navigator.of(context).pop();
                  }
                  else{
                    Navigator.of(context).pop();
                    showOfflineDialog();
                  }
                  _updateFirebaseDataForStartTuning(Tuning.stop);
                  
                },
                child: const Text('Finish'),
              ),
            ],
          ),
        );
      },
    );
  }

  void showOfflineDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Can't start tuning! Your device seems to be offline, check your connection and try again."),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: ()  {
                  Navigator.of(context).pop();
                  _updateFirebaseDataForStartTuning(Tuning.stop);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  void showSendingErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("There was an error sending data, try again later"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: ()  {
                  Navigator.of(context).pop();
                  _updateFirebaseDataForStartTuning(Tuning.stop);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateFirebaseDataForWatering() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref(groundSettingsPath);

    Map<String, dynamic> updateData = {
      'low_moist': (lowMoistValue).round(), 
      'new ground settings': 1,
      'high_moist': (highMoistValue).round(),
    };
    await ref.update(updateData);
  }

  void _updateFirebaseDataForDry() async {
      DatabaseReference ref = FirebaseDatabase.instance.ref(groundSettingsPath);

      Map<String, dynamic> updateData = {
        'dry_value': (dryGroundValue).round(), 
        'new ground settings': 1,
      };
      await ref.update(updateData);
  }
  void _updateFirebaseDataForStartTuning(Tuning tuning) async {
      DatabaseReference ref = FirebaseDatabase.instance.ref(groundSettingsPath);
      Map<String, dynamic> updateData;
      if(tuning == Tuning.start){
      updateData = {
        'tuning': 1,
      };
      }
      else{
        updateData = {
        'tuning': 0,
      };
      }
      await ref.update(updateData);
  }

}

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const CustomButton({required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 5, 
      ),
      child: Container(
        padding: const EdgeInsets.all(15.0),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16.0),
        ),
      ),
    );
  }
}

// Widget that changes its text whenever MyHomeScreen's state changes
class GroundReadingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MyHomeScreenNotifier>(
    builder: (context, cart, child) {
      DateTime now = DateTime.now();
      return Column(
        children: [
          // Text("got info ${now.difference(lastReading!.timestamp!).inSeconds} sec ago"),
          // Text("Status:${now.difference(lastReading!.timestamp!).inSeconds <  tuningDelta + 5 ? "online" : "offline"}"),
          Card(child: Text('${lastReading!.moisture!}%')),
        ],
      );
    },);
  }
}