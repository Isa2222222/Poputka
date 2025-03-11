import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.primary,
      ),
      body: const Center(
        child: Text('Messages will be shown here'),
      ),
    );
  }
}
