import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';
import 'settings_screen.dart';

List<Color> statusList = [];

class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});

  @override
  _MyHomeScreenState createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {

  @override
  Widget build(BuildContext context) {
    if (lastReading == null) {
      return const Center(child: Text('No Data...'));
    }

    String lastConnectedText = '';

    if (statusList.isNotEmpty && statusList[0] == Colors.red && timestamp != null) {
      // Wi-Fi connection is red
      if (difference!.inSeconds < 60) {
        lastConnectedText = ' (last time connected: ${difference?.inSeconds} seconds)';
      } else if (difference!.inSeconds < 3600) {
        lastConnectedText = ' (last time connected: ${difference?.inMinutes} minutes)';
      } else if (difference!.inSeconds < 86400) {
        lastConnectedText = ' (last time connected: ${difference?.inHours} hours)';
      } else {
        lastConnectedText = ' (last time connected: ${difference?.inDays} days)';
      }
    }

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(35),
          child: Text(
            'Status',
            style: TextStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        _buildSensorStatusCircle(isSensorWorking: true),
        _buildSensorStatusCircle(isSensorWorking: false),
        Padding(
          padding: const EdgeInsets.all(35),
          child: Text(
            'Current Readings$lastConnectedText',
            style: const TextStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        if (statusList.isNotEmpty && statusList[0] == Colors.green) ...[
          _buildReadingRow('Wi-Fi connection', '', statusList[0]),
          _buildReadingRow('Humidity (%)', lastReading?['humidity'], statusList[4]),
          _buildReadingRow('Light level (%)', lastReading?['light'], statusList[1]),
          _buildReadingRow('Moisture (%)', lastReading?['moisture'], statusList[2]),
          _buildReadingRow('Temperature (C)', lastReading?['temperature'], statusList[3]),
        ] else if (statusList.isNotEmpty && statusList[0] == Colors.red)
          _buildReadingRow('Wi-Fi connection', '', statusList[0]),
      ],
    );
  }

  Widget _buildSensorStatusCircle({required bool isSensorWorking}) {
    final Color circleColor = isSensorWorking ? Colors.green : Colors.red;
    final String statusText = isSensorWorking ? 'Working' : 'Not working';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 35.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
              border: Border.all(
                color: Colors.white,
                width: 2.0,
              ),
            ),
            child: const CircleAvatar(
              radius: 5.0,
              backgroundColor: Colors.transparent,
            ),
          ),
          const SizedBox(width: 10.0),
          Text(
            statusText,
            style: const TextStyle(
              fontSize: 18.0,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingRow(String label, dynamic value, Color circleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 35.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
              border: Border.all(
                color: Colors.white,
                width: 2.0,
              ),
            ),
            child: const CircleAvatar(
              radius: 5.0,
              backgroundColor: Colors.transparent,
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$label ',
                      style: const TextStyle(
                        fontSize: 27.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 18.0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _listenToFirebase();
    _scanForStatus();
  }

  void _scanForStatus() {
    if (timestamp != null) {
      DateTime now = DateTime.now();
      difference = now.difference(timestamp!);

      if (difference!.inSeconds < sendInfoToDatabaseValue + 20) {
        statusList.add(Colors.green);
      } else {
        statusList.add(Colors.red);
      }
      if (lastReading?['light'] != 100) {
        statusList.add(Colors.green);
      } else {
        statusList.add(Colors.red);
      }
      if (lastReading?['moisture'] != 100) {
        statusList.add(Colors.green);
      } else {
        statusList.add(Colors.red);
      }
      if (lastReading?['temperature'] != 100) {
        statusList.add(Colors.green);
      } else {
        statusList.add(Colors.red);
      }
      if (lastReading?['humidity'] != 100) {
        statusList.add(Colors.green);
      } else {
        statusList.add(Colors.red);
      }
    }
  }

  void _listenToFirebase() {
    databaseReference.child(readingsPath).onChildAdded.listen((DatabaseEvent event) {
      setState(() {
        lastReading = (event.snapshot.value) as Map;
        timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(event.snapshot.key ?? '') * 1000);
      });
    });
  }
}