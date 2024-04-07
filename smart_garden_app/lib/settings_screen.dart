import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';

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

  void _fetchInitialValues(){
    databaseReference.child(settingsPath).onValue.listen((DatabaseEvent event){
      setState(() {
        print("got new settings reading!");
        Map fields = event.snapshot.value as Map;
        displayTimeoutValue = fields['display time out'];
        sendInfoToDatabaseValue = fields['send information to database'];
        });
    });
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
                    min: 10,
                    max: 100,
                    divisions: 90,
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
                    min: 10,
                    max: 60,
                    divisions: 50,
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
              onPressed: (){
                _updateFirebaseData();
                Navigator.pop(context);
              },
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
      'display time out': (displayTimeoutValue).round(),
      'new settings': 1,
      'send information to database': (sendInfoToDatabaseValue).round(),
    };

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
