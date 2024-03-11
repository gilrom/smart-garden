import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'my_home_screen.dart';
import 'stats_screen.dart';
<<<<<<< HEAD
import 'settings_screen.dart';
import 'ground_settings_screen.dart';
=======
>>>>>>> Gil

//Globals
final databaseReference = FirebaseDatabase.instance.ref();
const String readingsPath = 'UsersData/LUU0e7Ux9CbJljnUIIIHq9yk3RF2/readings';
<<<<<<< HEAD
const String settingsPath = 'UsersData/LUU0e7Ux9CbJljnUIIIHq9yk3RF2/settings';
const String groundSettingsPath = 'UsersData/LUU0e7Ux9CbJljnUIIIHq9yk3RF2/groundSettings';


=======
>>>>>>> Gil


void main() async {
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Garden App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 31, 155, 0)),
        // brightness: Brightness.dark
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const MyHomeScreen(),
    const StatsScreen(),
<<<<<<< HEAD
    const SettingsScreen(),
    const GroundSettingsScreen(),
=======
    const ProfileScreen(),
>>>>>>> Gil
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Garden App',
        style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onSecondary)),
        backgroundColor: Theme.of(context).colorScheme.primary
      ),
      body: Container(child: _tabs[_currentIndex],),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
<<<<<<< HEAD
        backgroundColor: Theme.of(context).colorScheme.primary,
        selectedItemColor: Theme.of(context).colorScheme.onPrimary,
        unselectedItemColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
=======
>>>>>>> Gil
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
<<<<<<< HEAD
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grass),
            label: 'Ground',
=======
            icon: Icon(Icons.person),
            label: 'Profile',
>>>>>>> Gil
          ),
        ],
      ),
    );
  }
}
<<<<<<< HEAD
/*
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
=======

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
>>>>>>> Gil

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile Screen'),
    );
  }
<<<<<<< HEAD
}
*/
=======
}
>>>>>>> Gil
