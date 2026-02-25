import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';

class HomeScreenTab extends StatelessWidget {
  const HomeScreenTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      title: "Techmates",
      showLeadingAvatar: false,
      titleWidget: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Tech',
              style: TextStyle(
                color: Colors.red,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
                height: 1.0,
              ),
            ),
            TextSpan(
              text: 'mates',
              style: TextStyle(
                color: Color(0xFF0046FF),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
      child: Center(
        child: Text('Coming Soon'),
      ),
    );
  }
}
