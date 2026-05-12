import 'package:flutter/material.dart';

class SewacBackground extends StatelessWidget {
  final Widget child;

  const SewacBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        Positioned.fill(
          child: Image.asset(
            "assets/images/login_bg.jpeg",
            fit: BoxFit.cover,
          ),
        ),

        Positioned.fill(
          child: Container(
            color: Colors.white.withOpacity(0.72),
          ),
        ),

        child,
      ],
    );
  }
}