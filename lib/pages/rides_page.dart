import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class RidesPage extends StatelessWidget {
  const RidesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rides'),
        backgroundColor: AppColors.primary,
      ),
      body: const Center(
        child: Text('Rides will be shown here'),
      ),
    );
  }
}
