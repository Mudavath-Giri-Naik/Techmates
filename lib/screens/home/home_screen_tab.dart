import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';

class HomeScreenTab extends StatelessWidget {
  const HomeScreenTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      title: "Techmates",
      child: Center(
        child: Text('Coming Soon'),
      ),
    );
  }
}
