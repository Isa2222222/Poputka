import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/bottom_nav_bar.dart';
import '../pages/home_page.dart';
import '../pages/rides_page.dart';
import '../pages/messages_page.dart';
import '../pages/profile_page.dart';
import '../models/ride_model.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return Scaffold(
          body: child,
          bottomNavigationBar: BottomNavBar(
            currentIndex: _calculateSelectedIndex(state.uri.path),
          ),
        );
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) {
            // Проверяем, есть ли параметр rideToEdit
            final Map<String, dynamic>? args =
                state.extra as Map<String, dynamic>?;
            final RideModel? rideToEdit = args?['rideToEdit'];
            return HomePage(rideToEdit: rideToEdit);
          },
        ),
        GoRoute(
          path: '/rides',
          builder: (context, state) => const RidesPage(),
        ),
        GoRoute(
          path: '/messages',
          builder: (context, state) => const MessagesPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),
  ],
);

int _calculateSelectedIndex(String location) {
  if (location.startsWith('/rides')) return 1;
  if (location.startsWith('/messages')) return 2;
  if (location.startsWith('/profile')) return 3;
  return 0;
}
