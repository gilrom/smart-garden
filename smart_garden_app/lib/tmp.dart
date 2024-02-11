import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Database Example',
      theme: ThemeData(
        primarySwatch: Color.fromARGB(255, 44, 131, 4),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final databaseReference = FirebaseDatabase.instance.ref();
  MapEntry? lastReading;
  
  @override
  void initState() {
    super.initState();
    //getting last entry once at app startup
    _getLatestDataFromFirebase();
    //Listen to new values all time. Old value of lastReading is overrided.
    _listenToFirebase();
  }

  void _getLatestDataFromFirebase() async {
    final snapshot = await databaseReference.child('UsersData/LUU0e7Ux9CbJljnUIIIHq9yk3RF2/readings').get();
    if (snapshot.exists) {
      print("Got data from Firebase!")
      lastReading = (snapshot as Map).entries.last;
    } else {
      print('No data available!');
    }
  }
  void _listenToFirebase() {
    databaseReference.child('UsersData/LUU0e7Ux9CbJljnUIIIHq9yk3RF2/readings').onValue.listen((DatabaseEvent event){
      setState(() {
        lastReading = event.snapshot as MapEntry;
        print("Got Data");
        print(lastReading);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bottom Navigation Demo'),
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Home Screen'),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Favorites Screen'),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Profile Screen'),
    );
  }
}