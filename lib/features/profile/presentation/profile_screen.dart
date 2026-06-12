import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Câu chuyện sức khỏe của bạn')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          SizedBox(height: 20),
          ListTile(
            title: Text('Mình gọi bạn là'),
            subtitle: Text('Dao Van Hung'),
          ),
          ListTile(
            title: Text('Điều chúng ta đang hướng tới'),
            subtitle: Text('Khỏe hơn theo cách phù hợp với bạn'),
          ),
        ],
      ),
    );
  }
}
