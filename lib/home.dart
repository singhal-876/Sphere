import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top section with image and status container
          Container(
            margin: const EdgeInsets.only(top: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: const Color.fromARGB(255, 223, 218, 226),
            ),
            height:
                MediaQuery.of(context).size.height * 0.3, // 30% of page height
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // color: Color.fromARGB(255, 223, 218, 226),
                // Image on the left side
                Container(
                  width: MediaQuery.of(context).size.width *
                      0.4, // 40% of screen width
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                          'assets/images/watch.png'), // Replace with your image URL
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(
                    width: 10), // Space between image and status container

                // Status container on the right side
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 193, 186, 222),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("CONNECTED"),
                        Text("Battery Status: FULL"),
                        Text("GPS Tracking: ON"),
                        Text("Safety Status: YES"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20), // Space between containers

          // SOS Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(60),
                textStyle: const TextStyle(fontSize: 50),
                shape: const CircleBorder(),
              ),
              onPressed: () {
                // Add SOS functionality here
              },
              child: const Text("SOS", style: TextStyle(color: Colors.white)),
            ),
          ),

          const SizedBox(
              height: 20), // Space between SOS button and bottom section

          // Bottom section with "Add Contacts" and "Start/Stop Sharing Location" options
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Add contacts option on the left side
                  ElevatedButton.icon(
                    onPressed: () {
                      // Add contacts functionality here
                    },
                    icon: const Icon(Icons.contacts),
                    label: const Text("Add Contacts"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),

                  // Start/Stop Sharing Location option on the right side
                  ElevatedButton.icon(
                    onPressed: () {
                      // Start/Stop sharing location functionality here
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text("Start/Stop Sharing Location"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
