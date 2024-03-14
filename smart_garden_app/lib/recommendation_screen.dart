import 'package:flutter/material.dart';
import 'ground_settings_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';
import 'my_home_screen.dart';

double? currentMoist;

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final int recommendWateringTime = 12;
  

  @override
  Widget build(BuildContext context) {
    print(buttonGroundValue);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommendation status',
              style: TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 42),
            Card(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Current soil moisture level",
                    style: TextStyle(
                      fontSize: 27.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${lastReading!.moisture!} %",
                    style: const TextStyle(fontSize: 18.0, color:Color.fromARGB(255, 0, 0, 0)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Preferred soil moisture level",
                    style: TextStyle(
                      fontSize: 27.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$highGroundValue %",
                    style: const TextStyle(fontSize: 18.0, color: Color.fromARGB(255, 0, 0, 0)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Watering threshold level",
                    style: TextStyle(
                      fontSize: 27.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$buttonGroundValue %",
                    style: const TextStyle(fontSize: 18.0, color: Color.fromARGB(255, 0, 0, 0)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Minimal soil moisture level",
                    style: TextStyle(
                      fontSize: 27.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$dryGroundValue %",
                    style: const TextStyle(fontSize: 18.0, color:Color.fromARGB(255, 0, 0, 0)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchInitialValues();
  }

  void _fetchInitialValues() async {
    final refn = FirebaseDatabase.instance.ref();
    final snapshot = await refn.child(groundSettingsPath).get();
    Map<dynamic, dynamic>? values = snapshot.value as Map<dynamic, dynamic>?;

    if (values != null) {
      setState(() {
        highGroundValue = (values['high ground value']);
        buttonGroundValue = (values['button ground value']);

      });
    }
  }
}