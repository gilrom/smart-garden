import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'my_home_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'ground_settings_screen.dart';
import 'recommendation_screen.dart';
import 'wifi_screen.dart';
import 'bluetooth_screen.dart';

//Globals
final databaseReference = FirebaseDatabase.instance.ref();
const String readingsPath = 'UsersData/LUU0e7Ux9CbJljnUIIIHq9yk3RF2/readings';
const String settingsPath = 'UsersData/LUU0e7Ux9CbJljnUIIIHq9yk3RF2/settings';
const String groundSettingsPath = 'UsersData/LUU0e7Ux9CbJljnUIIIHq9yk3RF2/groundSettings';
Map? lastReading;



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Garden App',
      theme: ThemeData.dark().copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          titleTextStyle: TextStyle(color: Colors.white),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 25, 25, 25),
        primaryColor: const Color.fromARGB(255, 25, 25, 25),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey.withOpacity(0.5),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}



class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const MyHomeScreen(),
    const StatsScreen(),
    const RecommendationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Garden App',
        ),
      ),
      body: Container(
        child: _tabs[_currentIndex],
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            ListTile(
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen(const SettingsScreen());
              },
            ),
            ListTile(
              title: const Text('Soil level measuring'),
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen(const GroundSettingsScreen());
              },
            ),
            ListTile(
              title: const Text('Wi-Fi'),
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen(const WifiScreen());
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.area_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.recommend),
            label: 'Recommendation',
          ),
        ],
      ),
    );
  }

 void _navigateToScreen(Widget screen) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Material(
        child: screen,
      ),
    ),
  );
}
}