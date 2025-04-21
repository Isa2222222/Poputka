import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/home_page.dart';
import 'pages/rides_page.dart';
import 'pages/messages_page.dart';
import 'pages/profile_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/edit_profile_page.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/pocketbase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await pocketBaseService.initAuth();
  await pocketBaseService.saveAuthState();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Poputka',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFC107)),
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isAuthenticated = pocketBaseService.isAuthenticated();
    final isLoggingIn = state.matchedLocation == '/login';
    final isRegistering = state.matchedLocation == '/register';

    if (!isAuthenticated && !isLoggingIn && !isRegistering) {
      return '/login';
    }

    if (isAuthenticated && (isLoggingIn || isRegistering)) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return EditProfilePage(initialData: extra);
      },
    ),
    ShellRoute(
      builder: (context, state, child) {
        final location = state.matchedLocation;
        int currentIndex;
        switch (location) {
          case '/':
            currentIndex = 0;
            break;
          case '/rides':
            currentIndex = 1;
            break;
          case '/messages':
            currentIndex = 2;
            break;
          case '/profile':
            currentIndex = 3;
            break;
          default:
            currentIndex = 0;
        }

        return Scaffold(
          body: child,
          bottomNavigationBar: BottomNavBar(currentIndex: currentIndex),
        );
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final rideToEdit = extra?['rideToEdit'];
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
