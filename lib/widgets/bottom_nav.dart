import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AppBottomNav extends StatelessWidget {
  final int index;
  const AppBottomNav({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: index,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Consts.primaryColor,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      onTap: (i) {
        switch (i) {
          case 0:
            Navigator.of(context).pushReplacementNamed('/home');
            break;
          case 1:
            Navigator.of(context).pushReplacementNamed('/explore');
            break;
          case 2:
            Navigator.of(context).pushReplacementNamed('/wishlist');
            break;
          case 3:
            Navigator.of(context).pushReplacementNamed('/account');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ទំព័រដើម'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'ស្វែងរក'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'ពេញចិត្ត'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'គណនី'),
      ],
    );
  }
}
