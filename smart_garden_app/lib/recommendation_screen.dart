import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  var high_moist;
  var low_moist;
  var dry_moist;

  @override
  Widget build(BuildContext context) {

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
            // const SizedBox(height: 42),
            // Card(
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       const Text(
            //         "Current soil moisture level",
            //         style: TextStyle(
            //           fontSize: 15,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //       Text(
            //         "${lastReading!.moisture!} %",
            //         style: const TextStyle(fontSize: 18.0, color:Color.fromARGB(255, 0, 0, 0)),
            //       )
            //     ],
            //   ),
            // ),
            const SizedBox(height: 20),
            Card(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Preferred soil moisture level",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$high_moist %",
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$low_moist %",
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$dry_moist %",
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

  void _fetchInitialValues() {
    databaseReference.child(groundSettingsPath).onValue.listen((DatabaseEvent event){
      setState(() {
        Map fields = event.snapshot.value as Map;
        high_moist = fields['high_moist'];
        low_moist = fields['low_moist'];
        dry_moist = fields['dry_value'];
        });
    });
  }
}