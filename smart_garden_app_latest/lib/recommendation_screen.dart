import 'package:flutter/material.dart';
import 'ground_settings_screen.dart';
import 'main.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final int recommendWateringTime = 12;

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
            const SizedBox(height: 42),
            Row(
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
                  "${lastReading?['moisture']}",
                  style: const TextStyle(fontSize: 18.0, color: Colors.white),
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
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
                  "$highGroundValue",
                  style: const TextStyle(fontSize: 18.0, color: Colors.white),
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
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
                  "$buttonGroundValue",
                  style: const TextStyle(fontSize: 18.0, color: Colors.white),
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Water the soil in:",
                  style: TextStyle(
                    fontSize: 27.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "$recommendWateringTime hours",
                  style: const TextStyle(fontSize: 18.0, color: Colors.white),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }
}
