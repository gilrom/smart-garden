import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';

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
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(35),
          child: Text(
            'Last Readings',
            style: TextStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        for (var e in lastReading!.entries)
          _buildReadingRow(e.key, e.value),
      ],
    );
  }

 Widget _buildReadingRow(String label, dynamic value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 35.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 27.0, 
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
  );
}


  @override
  void initState() {
    super.initState();
    _listenToFirebase();
  }

  void _listenToFirebase() {
    databaseReference.child(readingsPath).onChildAdded.listen((DatabaseEvent event) {
      setState(() {
        lastReading = (event.snapshot.value) as Map;
      });
    });
  }
}
