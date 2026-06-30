import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gapfix/models/tutor_model.dart';
import 'package:gapfix/core/theme.dart';
import 'package:gapfix/features/shop/widgets/booking_bottom_sheet.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class TutorProfileScreen extends StatelessWidget {
  final TutorModel tutor;

  const TutorProfileScreen({super.key, required this.tutor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    final accentBgColor = isDark ? AppTheme.accentBgDark : AppTheme.accentBgLight;
    final slateMediumColor = isDark ? AppTheme.slateMediumDark : AppTheme.slateMediumLight;
    final warningColor = isDark ? AppTheme.warningDark : AppTheme.warningLight;
    final slateDarkColor = isDark ? AppTheme.slateDarkD : AppTheme.slateDarkLight;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // Banner Image
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        image: (tutor.imageResourceLink != null && tutor.imageResourceLink!.isNotEmpty)
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(tutor.imageResourceLink!),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.3),
                                  BlendMode.darken,
                                ),
                              )
                            : null,
                      ),
                      child: (tutor.imageResourceLink == null || tutor.imageResourceLink!.isEmpty)
                          ? Center(
                              child: Icon(Icons.person, size: 80, color: theme.primaryColor.withValues(alpha: 0.5)),
                            )
                          : null,
                    ),
                    // Back Button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black26,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    // Profile Image (Overlapping bottom center)
                    Positioned(
                      top: 133, // 180 - 47 (half of 94)
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 47,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: (tutor.imageResourceLink != null && tutor.imageResourceLink!.isNotEmpty)
                              ? CachedNetworkImageProvider(tutor.imageResourceLink!)
                              : null,
                          child: (tutor.imageResourceLink == null || tutor.imageResourceLink!.isEmpty)
                              ? const Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 60)), // Space for avatar overlap + padding

              // Name and Subtitle
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        tutor.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Available subjects and rates',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Tutor Profile Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: slateMediumColor, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tutor Profile',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Rating Card
                              Container(
                                width: 120,
                                decoration: BoxDecoration(
                                  color: accentBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    const Text(
                                      '4.8',
                                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    RatingBarIndicator(
                                      rating: 4.8,
                                      itemBuilder: (context, index) => Icon(
                                        Icons.star,
                                        color: warningColor,
                                      ),
                                      unratedColor: slateDarkColor,
                                      itemCount: 5,
                                      itemSize: 14.0,
                                      direction: Axis.horizontal,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '4 reviews',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // About Section
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'About ${tutor.name}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tutor.bio,
                                      style: const TextStyle(fontSize: 12, height: 1.5),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Specialties Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Specialties',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Added by tutor',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: tutor.preferences.map((pref) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: theme.primaryColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        pref.name,
                                        style: TextStyle(
                                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark 
                                            ? AppTheme.iconBgGreenDark.withValues(alpha: 0.3) 
                                            : AppTheme.iconBgGreenLight,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '\$${pref.price} • 60 mins',
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Reviews Placeholder
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Text(
                    'Reviews',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)), // Space for bottom bar
            ],
          ),

          // Fixed Bottom Bar matching CoordinatorLayout gravity bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () => _showBookingSheet(context, true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      side: BorderSide(color: theme.primaryColor, width: 1.5),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Book Trial Lesson'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showBookingSheet(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Book Lesson'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trial is 30 mins paid',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingSheet(BuildContext context, bool isTrial) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingBottomSheet(tutor: tutor, isTrial: isTrial),
    );
  }
}

