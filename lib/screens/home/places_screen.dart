import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/firebase_service.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  static const Color primaryBlue = Color(0xFF1B4FD8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Favorite Places',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

              // READ: live list of saved favorites
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirebaseService.streamDocuments('saved_places'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: primaryBlue));
                    }
                    final favorites = snapshot.data ?? [];
                    if (favorites.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            const Text(
                              'No favorite places yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap the heart icon on a search result to save it',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final item = favorites[index];
                        return Dismissible(
                          key: Key(item['id']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          // DELETE: remove favorite on swipe
                          onDismissed: (direction) {
                            FirebaseService.deleteDocument('saved_places', item['id']);
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.favorite, color: Colors.red),
                              title: Text(item['name'] ?? ''),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                context.push('/results', extra: {'name': item['name']});
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) context.go('/');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Places'),
        ],
      ),
    );
  }
}