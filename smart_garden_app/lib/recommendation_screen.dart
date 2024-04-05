import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';
import 'my_home_screen.dart';

double lowMoistValue = 0.0; 
double highMoistValue = 0.0; 
double dryGroundValue = 0.0;

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  

  @override
  Widget build(BuildContext context) {
    print(lowMoistValue);
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
            //           fontSize: 27.0,
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
                      fontSize: 27.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$highMoistValue %",
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
                    "$lowMoistValue %",
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

  void _fetchInitialValues() {
    databaseReference.child(groundSettingsPath).onValue.listen((DatabaseEvent event){
      setState(() {
        print("got new recommendation reading!");
        Map fields = event.snapshot.value as Map;
        highMoistValue = fields['high_moist'];
        lowMoistValue = fields['low_moist'];
        dryGroundValue = fields['dry_value'];
        });
    });
  }
}