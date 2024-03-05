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

  Future<void> _fetchInitialValues() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref(settingsPath);

    try {
      final ref = FirebaseDatabase.instance.ref();
      final snapshot = await ref.child(settingsPath).get();
      Map<dynamic, dynamic>? values = snapshot.value as Map<dynamic, dynamic>?;

      if (values != null) {
        setState(() {
          displayTimeoutValue = (values['display time out']?.toDouble() ?? 50000) / 1000;
          sendInfoToDatabaseValue = (values['send information to database']?.toDouble() ?? 60000) / 1000;
        });
      }
    } catch (e) {
      print("Error fetching initial values: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
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
          SizedBox(height: 20),
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
          SizedBox(height: 20),
          Text('Wi-Fi Settings:'),
          Container(
            width: 200,
            child: TextField(
              decoration: InputDecoration(labelText: 'Wi-Fi Name'),
              onChanged: (value) {
                setState(() {
                  wifiName = value;
                });
              },
            ),
          ),
          Container(
            width: 200,
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Wi-Fi Password',
                suffixIcon: IconButton(
                  icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                ),
              ),
              obscureText: !showPassword,
              onChanged: (value) {
                setState(() {
                  wifiPassword = value;
                });
              },
            ),
          ),
          SizedBox(height: 20),
          Container(
            width: 200,
            child: CustomButton(
              onPressed: _updateFirebaseData,
              label: 'Update Settings',
            ),
          ),
        ],
      ),
    );
  }

  void _updateFirebaseData() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref(settingsPath);

      Map<String, dynamic> updateData = {
        'display time out': (displayTimeoutValue * 1000).round(),
        'new settings': 1,
        'send information to database': (sendInfoToDatabaseValue * 1000).round(),
      };
      if (wifiName.isNotEmpty && wifiPassword.isNotEmpty) {
        updateData['wifi name'] = wifiName;
        updateData['wifi password'] = wifiPassword;
      } else {
        if (wifiPassword.isNotEmpty) {
          _showErrorDialog("Rewrite Wi-Fi name, and try again.");
          return;
        } else {
          if (wifiName.isNotEmpty) {
            _showErrorDialog("Rewrite Wi-Fi name, and try again.");
            return;
          }
        }
      }

      await ref.update(updateData);

      await _fetchInitialValues();
    } catch (e) {
      print("Error updating Firebase data: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
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
        padding: EdgeInsets.all(10.0),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.0),
        ),
      ),
    );
  }
}
