import 'package:flutter/material.dart';

class EliteBadge extends StatelessWidget {
  const EliteBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 5,
            color: Colors.white,
          ),
          const SizedBox(width: 1),
          const Text(
            'ELITE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
