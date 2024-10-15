import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sphere/ble_devices_page.dart';
import 'package:sphere/nearby_users_service.dart';
// import 'community_page.dart';
// import 'ble_devices_page.dart'; // BLE device page for heart rate monitor
import 'location_sharing.dart'; // Location Sharing Page
import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SphereApp());
}

class SphereApp extends StatelessWidget {
  const SphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sphere',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthPage(), // Set AuthPage as the home widget
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isSignIn = true;
  String email = '';
  String password = '';
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const HomePage())); // Navigate to HomePage
    } catch (e) {
      print(e);
    }
  }

  Future<void> signUp() async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Store the email in Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'email': email,
      });

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const HomePage())); // Navigate to HomePage
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSignIn ? 'Login' : 'Sign Up'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth > 600 ? 400 : screenWidth * 0.9,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        email = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        password = value;
                      });
                    },
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSignIn ? signIn : signUp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: Text(isSignIn ? 'Login' : 'Sign Up'),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isSignIn = !isSignIn;
                      });
                    },
                    child: Text(isSignIn
                        ? 'Create an account'
                        : 'Already have an account?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedItem = 0;

  final List<Widget> pages = [
    const Home(),
    NearbyUsersPage(),
    const LocationSharing(),
    BLEDevicesPage(), // Heart Rate via BLE Devices
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sphere"),
      ),
      drawer: const DrawerMenu(),
      body: pages[selectedItem],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.pink[100],
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.pink[200],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt), label: "Community"),
          BottomNavigationBarItem(
              icon: Icon(Icons.location_on), label: "Location"),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: "Heart Rate"),
        ],
        currentIndex: selectedItem,
        onTap: (value) {
          setState(() {
            selectedItem = value;
          });
        },
      ),
    );
  }
}

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: const <Widget>[
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_drawer_img.png'),
                fit: BoxFit.cover,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              radius: 80,
              backgroundImage: AssetImage('assets/images/sphere.png'),
            ),
            accountName: Text(
              "Sphere_username_1",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              "username1@gmail.com",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
          ),
          ListTile(
            leading: Icon(Icons.contact_mail),
            title: Text('Contact'),
          ),
        ],
      ),
    );
  }
}
