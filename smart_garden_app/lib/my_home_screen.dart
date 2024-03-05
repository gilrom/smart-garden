import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';



class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});
  @override
  _MyHomeScreenState createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {
  Map? lastReading;

  @override
  Widget build(BuildContext context) {
    if (lastReading == null) {
      return const Center(child: Text('No Data...'));
    }
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text('Last Readings'),
        ),
        for (var e in lastReading!.entries)
          Card(
            child: ListTile(
              title: Text("${e.value}"),
              subtitle: Text("${e.key}"),
            ),
          ),
      ],
    );
}

  @override
  void initState() {
    super.initState();
    _listenToFirebase();
  }

  void _listenToFirebase() {
    databaseReference.child(readingsPath).onChildAdded.listen((DatabaseEvent event){
      setState(() {
        lastReading = (event.snapshot.value) as Map;
        // print("Got new Data");
        // print(lastReading);
        });
      });
  }
}
