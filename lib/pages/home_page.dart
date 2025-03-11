import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../constants/app_colors.dart';
import '../widgets/area_selector.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  RecordModel? fromArea;
  RecordModel? toArea;
  bool isDriver = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Logo and language selector row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/logo.png', height: 40),
                  Row(
                    children: [
                      Image.asset('assets/images/ru_flag.png', height: 24),
                      const SizedBox(width: 16),
                      const Icon(Icons.notifications_outlined),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // User type selector
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => isDriver = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            !isDriver ? AppColors.primary : Colors.white,
                        foregroundColor:
                            !isDriver ? Colors.white : Colors.black,
                      ),
                      child: const Text('Найти попутчика'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => isDriver = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDriver ? AppColors.primary : Colors.white,
                        foregroundColor: isDriver ? Colors.white : Colors.black,
                      ),
                      child: const Text('Я водитель'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // From and To fields with area selectors
              AreaSelector(
                hintText: 'Откуда',
                onAreaSelected: (area) {
                  setState(() => fromArea = area);
                },
              ),
              const SizedBox(height: 12),
              AreaSelector(
                hintText: 'Куда',
                onAreaSelected: (area) {
                  setState(() => toArea = area);
                },
              ),
              const SizedBox(height: 20),

              // Date and Passengers row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.calendar_today),
                          SizedBox(width: 8),
                          Text('Выберите дни'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.access_time),
                          SizedBox(width: 8),
                          Text('Выберите время'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isDriver ? 'Найти пассажиров' : 'Найти водителя',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              // Banner image
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/images/banner.png'),
              ),

              // Contact number
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.phone),
                    SizedBox(width: 8),
                    Text('+996 (706) 880 087'),
                  ],
                ),
              ),

              // Social media links
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.wechat),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.telegram),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
