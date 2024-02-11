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
      title: 'Smart Garden App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 30, 102, 33)),
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
        title: Text('Smart Garden App'),
      ),
      body: Container(child: _tabs[_currentIndex], color: Theme.of(context).colorScheme.primaryContainer,),
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
    if (lastReading == null) {
      return Center(child: Text('No Data...'));
    }
    // List<Card> list = lastReading!.entries.map((e) {
    //   return Card(child: ListTile(title: Text("${e.value}"),subtitle: Text("${e.key}"),));
    // }).toList();
    // list.insert(0, Card(child: Text("Last Readings")));
    // return ListView(children:list);
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
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
    databaseReference.child('UsersData/LUU0e7Ux9CbJljnUIIIHq9yk3RF2/readings').onChildAdded.listen((DatabaseEvent event){
      setState(() {
        lastReading = (event.snapshot.value) as Map;
        print("Got new Data");
        print(lastReading);
        });
      });
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

// class BigCard extends StatelessWidget {
//   const BigCard({
//     super.key,
//     required this.txt,
//   });

//   final String txt;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final style = theme.textTheme.displayMedium!.copyWith(
//       color: theme.colorScheme.onPrimary,
//     );

//     return Card(
//       color: theme.colorScheme.primary,
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Text(
//           txt,
//           style: style,
//         ),
//       ),
//     );
//   }
// }