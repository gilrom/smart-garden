import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';

double displayTimeoutValue = 50;
double sendInfoToDatabaseValue = 60;
String wifiName = '';
String wifiPassword = '';
bool showPassword = false;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    _fetchInitialValues();
  }

  void _fetchInitialValues() async {
    //DatabaseReference ref = FirebaseDatabase.instance.ref(settingsPath);
    final refn = FirebaseDatabase.instance.ref();
    final snapshot = await refn.child(settingsPath).get();
    Map<dynamic, dynamic>? values = snapshot.value as Map<dynamic, dynamic>?;

    if (values != null) {
      setState(() {
        displayTimeoutValue = (values['display time out']?.toDouble() ?? 50000) / 1000;
        sendInfoToDatabaseValue = (values['send information to database']?.toDouble() ?? 60000) / 1000;
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Settings'),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text('Display Timeout: ${displayTimeoutValue.round()} seconds'),
                  Slider(
                    value: displayTimeoutValue,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (value) {
                      setState(() {
                        displayTimeoutValue = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text('Send Info to Database: ${sendInfoToDatabaseValue.round()} seconds'),
                  Slider(
                    value: sendInfoToDatabaseValue,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (value) {
                      setState(() {
                        sendInfoToDatabaseValue = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            child: CustomButton(
              onPressed: _updateFirebaseData,
              label: 'Update Settings',
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _updateFirebaseData() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref(settingsPath);

    Map<String, dynamic> updateData = {
      'display time out': (displayTimeoutValue * 1000).round(),
      'new settings': 1,
      'send information to database': (sendInfoToDatabaseValue * 1000).round(),
    };

    await ref.update(updateData);

    _fetchInitialValues();
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
        width: double.infinity,
        padding: const EdgeInsets.all(10.0),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14.0),
        ),
      ),
    );
  }
}
