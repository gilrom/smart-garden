import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'reading.dart';

Map? lastExistingReading;
final databaseReference = FirebaseDatabase.instance.ref();

void fetchExistingLastReading() async {
  final event = await databaseReference.child('UsersData/LUU0e7Ux9CbJljnUIIIHq9yk3RF2/readings').once(DatabaseEventType.value);
  if (event.snapshot.exists) {
      print("Got data from Firebase!");
      lastExistingReading = Map.from((event.snapshot.value as Map).entries.last.value);
      print(lastExistingReading);
    } else {
      lastExistingReading = null;
      print('No data available!');
    }
}

void main() async {
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,);
  fetchExistingLastReading();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Garden App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    MyHomeScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];
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

class MyHomeScreen extends StatefulWidget {
  @override
  _MyHomeScreenState createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {
  final databaseReference = FirebaseDatabase.instance.ref();
  Map? lastReading = null;

  @override
  Widget build(BuildContext context) {
    print("got here");
    return Scaffold(
      appBar: AppBar(
        title: Text('Last Readings:'),
      ),
      body: Container(child: () {
        Map? reading = lastReading;
        if (reading == null) {
          if(lastExistingReading == null){
            return Text('No Data...');
          }
          reading = lastExistingReading;
        }
        print("wow");
        print(reading);
        return ListView(
          children: reading!.entries.map((e) {
            return ListTile(
              title: Text("${e.key} : ${e.value}"),
            );
          }).toList(),
        );
      }()), 
    );
  }

  @override
  void initState() {
    super.initState();
    // _listenToFirebase();
  }

//   void _listenToFirebase() {
//     databaseReference.child('UsersData/LUU0e7Ux9CbJljnUIIIHq9yk3RF2/readings').onValue.listen((DatabaseEvent event){
//       setState(() {
//         lastReading = event.snapshot as MapEntry;
//         print("Got new Data");
//         print(lastReading);
//         });
//       });
//   }
// }
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