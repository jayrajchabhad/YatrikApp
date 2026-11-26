import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/hotel_repository.dart';
import '../../theme/app_theme.dart';

class AdminReviewsScreen extends StatelessWidget {
  const AdminReviewsScreen({
    super.key,
    this.repository = const FirestoreHotelRepository(),
  });

  final HotelRepository repository;

  Future<void> _deleteReview(BuildContext context, Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text('This review will be removed from the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await repository.deleteReview(review.id);
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete review: ${error.message ?? error.code}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: StreamBuilder<List<Review>>(
          stream: repository.watchReviews(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _Message(
                'Could not load reviews: ${snapshot.error}',
                isError: true,
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final reviews = snapshot.data!;
            final average = reviews.isEmpty
                ? 0.0
                : reviews.fold<double>(
                        0,
                        (total, review) => total + review.rating,
                      ) /
                      reviews.length;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Reviews & Ratings',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.star,
                      color: AppColors.accentGold,
                    ),
                    title: Text(average.toStringAsFixed(1)),
                    subtitle: Text('${reviews.length} reviews in Firestore'),
                  ),
                ),
                const SizedBox(height: 12),
                if (reviews.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No customer reviews yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...reviews.map(
                    (review) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    review.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${review.rating.toStringAsFixed(1)} ★',
                                  style: const TextStyle(
                                    color: AppColors.accentGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete review',
                                  onPressed: () =>
                                      _deleteReview(context, review),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              review.hotelTitle,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(review.comment),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: isError ? Colors.red : AppColors.textSecondary),
      ),
    ),
  );
}
