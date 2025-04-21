import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/ride_model.dart';
import 'ride_details_modal.dart';
import 'user_details_modal.dart';

class CompactRideCard extends StatelessWidget {
  final RideModel ride;
  final VoidCallback? onTap;

  const CompactRideCard({
    super.key,
    required this.ride,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Отладочная информация
    print('Building CompactRideCard:');
    print('- fromArea: ${ride.fromAreaName}');
    print('- toArea: ${ride.toAreaName}');
    print('- userName: ${ride.userName ?? 'null'}');
    print('- userId: ${ride.userId}');
    print('- date: ${ride.formattedDate}');
    print('- time: ${ride.formattedTime}');

    return GestureDetector(
      onTap: () => _showRideDetails(context),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info and time row
                Row(
                  children: [
                    // Avatar placeholder with tap gesture for user details
                    GestureDetector(
                      onTap: () => _showUserDetails(context),
                      child: _buildAvatarPlaceholder(),
                    ),
                    const SizedBox(width: 12),

                    // User name and date with tap gesture for user details
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showUserDetails(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.userShortName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              ride.formattedDate,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Time display
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ride.formattedTime,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Route display with ride type icon
                Row(
                  children: [
                    const Icon(Icons.route, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ride.routeString,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Show price if available
                    if (ride.price != null) ...[
                      Text(
                        '${ride.price!.toStringAsFixed(0)} ₽',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Ride type icon
                    if (ride.isDriver)
                      const Icon(Icons.drive_eta, color: Colors.green, size: 20)
                    else
                      const Icon(Icons.person, color: Colors.purple, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          ride.userInitial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _showRideDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RideDetailsModal(
          ride: ride,
          onContactPressed: () {
            // Handle contacting the user
            Navigator.of(context).pop();
            _showUserDetails(context);
          },
        );
      },
    );
  }

  void _showUserDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UserDetailsModal(
          userId: ride.userId,
          isDriver: ride.isDriver,
          onContactPressed: () {
            // Handle contacting the user
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Связь с пользователем...'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }
}
