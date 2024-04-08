import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';
import 'my_home_screen.dart';
import 'package:provider/provider.dart';
import 'package:linear_timer/linear_timer.dart';


enum Tuning {start, stop }


class GroundSettingsScreen extends StatefulWidget {
  const GroundSettingsScreen({super.key});

  @override
  _GroundSettingsScreenState createState() => _GroundSettingsScreenState();
}

class _GroundSettingsScreenState extends State<GroundSettingsScreen> {
  Duration tuningDuration = Duration(seconds:60);
  double lowMoistValue = 0.0; 
  double highMoistValue = 0.0; 
  double dryGroundValue = 0.0;
  @override
  Widget build(BuildContext ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soil Moisture calibration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              showInfoDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 100,),
          Text("Click 'Dry level tuning' to tune dry soil value"),
          Text("Click 'Wet levels tuning' to tune wet soil mid and high values"),
          SizedBox(height: 200,),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width - 40, 
                  child: CustomButton(
                    onPressed: () {
                      if(online){
                        _updateFirebaseDataForStartTuning(Tuning.start);
                        showSetupDialogForDry();
                      }
                      else{
                        showOfflineDialog();
                      }
                    },
                    label: 'Dry level tuning',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 40, 
                  child: CustomButton(
                    onPressed: () {
                      if(online){
                        _updateFirebaseDataForStartTuning(Tuning.start);
                        showSetupDialog();
                      }
                      else{
                        showOfflineDialog();
                      }
                    },
                    label: 'Wet levels tuning',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showInfoDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Moisure calibration explanation'),
          content: const Text(
            'Different soil types has different reaction to the moisture sensor. For system to know how to alert for your soil not being moist enough, we need to set 3 values. one for comletly dry soil, one for medium dump soil and one for highly dump soil. In this section we allow the user to tune this values.',
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
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Moist soil setup instructions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('We will now set the mid and the high values for soil moisture, starting with the mid value. Click "Continue" when you ready.'),
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
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Medium moisture level setup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Insert the moisture sensor into a slightly dump soil, This will be the mid value for soil moisture, wait at least 1 minute for stabilization. Click "Next" to continue'),
              const SizedBox(height: 20),
              LinearTimer(duration: tuningDuration),
              const GroundReadingWidget(),
              ElevatedButton(
                onPressed: () {
                  DateTime now = DateTime.now();
                  if(now.difference(lastReading!.timestamp!).inSeconds <  tuningDelta + 2){
                    lowMoistValue = double.parse(lastReading!.moisture!);
                    Navigator.of(context).pop();
                    showWaterSoilDialog();
                  }
                  else{
                    Navigator.of(context).pop();
                    showOfflineDialog();
                    _updateFirebaseDataForStartTuning(Tuning.stop);
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
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('High moisture value setup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Water the soil as much as you can. This value will be the high level for the sensor, wait at least 1 minute for stabilization. Click finish when ready.'),
            const SizedBox(height: 20),
            LinearTimer(duration: tuningDuration),
            const GroundReadingWidget(),
            ElevatedButton(
              onPressed: () {
                DateTime now = DateTime.now();
                print("diff${now.difference(lastReading!.timestamp!).inSeconds}");
                if(now.difference(lastReading!.timestamp!).inSeconds <  tuningDelta + 2){
                  highMoistValue = double.parse(lastReading!.moisture!); 
                  try {
                    _updateFirebaseDataForWatering();
                  }
                  catch(e){
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
void showSetupDialogForDry() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Setup Instructions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Put the moisture sensor in dry ground and wait for at least 1 minute.'),
              const Text(" Status bar will let you know 1 minute is over"),
              const SizedBox(height: 20),
              LinearTimer(duration: tuningDuration),
              const GroundReadingWidget(),
              ElevatedButton(
                onPressed: ()  {
                  DateTime now = DateTime.now();
                  if(now.difference(lastReading!.timestamp!).inSeconds <  tuningDelta + 2){
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
      barrierDismissible: false,
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
      barrierDismissible: false,
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

  const CustomButton({super.key, required this.onPressed, required this.label});

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
  const GroundReadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyHomeScreenNotifier>(
    builder: (context, cart, child) {
      DateTime now = DateTime.now();
      return Column(
        children: [
          // Text("got info ${now.difference(lastReading!.timestamp!).inSeconds} sec ago"),
          // Text("Status:${now.difference(lastReading!.timestamp!).inSeconds <  tuningDelta + 5 ? "online" : "offline"}"),
          Card(child: Text('Current Moisture: ${lastReading!.moisture!}%')),
        ],
      );
    },);
  }
}