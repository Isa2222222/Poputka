import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
      ),
      body: const Center(
        child: Text('Profile information will be shown here'),
      ),
    );
  }
}
