import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';

double displayTimeoutValue = 50;
double sendInfoToDatabaseValue = 60;
String wifiName = '';
String wifiPassword = '';
bool showPassword = false;

class WifiScreen extends StatefulWidget {
  const WifiScreen({Key? key}) : super(key: key);

  @override
  _WifiScreenState createState() => _WifiScreenState();
}

class _WifiScreenState extends State<WifiScreen> {
  @override
  void initState() {
    super.initState();
  }

   @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Wi-Fi'),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text('Wi-Fi Settings:'),
          SizedBox(
            width: 200,
            child: TextField(
              decoration: const InputDecoration(labelText: 'Wi-Fi Name'),
              onChanged: (value) {
                setState(() {
                  wifiName = value;
                });
              },
            ),
          ),
          SizedBox(
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
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            child: CustomButton(
              onPressed: _updateFirebaseData,
              label: 'Update Wifi',
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              "If Wi-Fi is not working or this is your first connection of the new device, please, check if your device connects via Bluetooth, we will send new Wi-Fi settings via Bluetooth connection",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.0, color: Colors.grey),
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
      'new wifi settings': 1,
    };
    if (wifiName.isNotEmpty && wifiPassword.isNotEmpty) {
      updateData['wifi name'] = wifiName;
      updateData['wifi password'] = wifiPassword;
      await ref.update(updateData);
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
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
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
