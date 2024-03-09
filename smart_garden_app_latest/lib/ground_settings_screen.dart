import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';

double buttonGroundValue = 0.0; 
double highGroundValue = 0.0; 
double dryGroundValue = 0.0;


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
        title: const Text('Soil level measuring'),
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
                  setGroundCondition('Watering the Soil');
                  showSetupDialog();
                },
                label: 'Watering the Soil',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: MediaQuery.of(context).size.width - 40, 
              child: CustomButton(
                onPressed: () {
                  setGroundCondition('Dry Ground');
                  showSetupDialogForDry();
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
              const Text('Insert the moisture sensor into the ground before watering, the sensor will be ready to read information. It will be ground level for the sensor, after getting to this level, the application will send you a notification to water the soil. Once you insert your sensor, you can proceed to the next step. Click "Next" to continue'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  buttonGroundValue = double.parse(lastReading?['moisture']);
                  Navigator.of(context).pop();
                  showWaterSoilDialog();
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
            const Text('Now water the soil as usual. This value will be a high level for the sensor, and you can see how much water you need for the next watering. Before you will click the "Finish" button please wait for 30 seconds for the better measering result'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                highGroundValue = double.parse(lastReading?['moisture']);
                Navigator.of(context).pop(); 
                _updateFirebaseDataForWatering();
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
              const Text('For this setup, you will need untoched, dry soil. Stick the sensor in the ground, when clicked "Finish" apllication will read information from sensor, and automaticaly update the dry ground value'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: ()  {
                  dryGroundValue = double.parse(lastReading?['moisture']);
                  Navigator.of(context).pop();
                  _updateFirebaseDataForDry();
                },
                child: const Text('Finish'),
              ),
            ],
          ),
        );
      },
    );
  }


  void _updateFirebaseDataForWatering() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref(groundSettingsPath);

      Map<String, dynamic> updateData = {
        'button ground value': (buttonGroundValue).round(), 
        'new ground settings': 1,
        'high ground value': (highGroundValue).round(),
      };
      await ref.update(updateData);
    } catch (e) {
      print("Error updating Firebase data: $e");
    }
  }

  void _updateFirebaseDataForDry() async {
      DatabaseReference ref = FirebaseDatabase.instance.ref(groundSettingsPath);

      Map<String, dynamic> updateData = {
        'dry ground value': (dryGroundValue).round(), 
        'new ground settings': 1,
      };
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