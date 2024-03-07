import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({Key? key}) : super(key: key);

  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final String deviceName = 'esp32-DCABE8';
  final String bluetoothName = 'YourESP32';
  final String connectedText = 'Connected';
  final String notConnectedText = 'Not connected';

  FlutterBlue flutterBlue = FlutterBlue.instance;
  bool isDeviceConnected = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    await flutterBlue.isOn.then((isOn) {
      if (isOn) {
        _scanForDevices();
      } else {
        print('Bluetooth is not available');
      }
    });
  }

  void _scanForDevices() {
    flutterBlue.startScan(timeout: const Duration(seconds: 4));

    flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        if (result.device.name == bluetoothName) {
          setState(() {
            isDeviceConnected = true;
          });
          return;
        }
      }
    });

    flutterBlue.stopScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your devices',
              style: TextStyle(
                fontSize: 38.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  deviceName,
                  style: const TextStyle(
                    fontSize: 27.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                isDeviceConnected
                    ? const Text(
                        'Connected',
                        style: TextStyle(color: Colors.green),
                      )
                    : const Text(
                        'Not connected',
                        style: TextStyle(color: Colors.red),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}