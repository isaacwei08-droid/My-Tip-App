import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant_model.dart';
import '../services/firestore_service.dart';
import '../widgets/draggable_scrollbar.dart';
import '../widgets/app_logo.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final Map<String, ({double rating, int reviewCount})> _savedRatings = {};

  void _showAddRestaurantDialog(BuildContext screenContext) {
    final nameController = TextEditingController();
    final cuisineController = TextEditingController();
    final cityController = TextEditingController();
    final streetController = TextEditingController();

    showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Add Restaurant"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Restaurant Name"),
            ),
            TextField(
              controller: cuisineController,
              decoration: const InputDecoration(labelText: "Cuisine"),
            ),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(labelText: "City"),
            ),
            TextField(
              controller: streetController,
              decoration: const InputDecoration(
                labelText: "Street (optional)",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final cuisine = cuisineController.text.trim();
              final city = cityController.text.trim();
              final street = streetController.text.trim();
              if (name.isNotEmpty && cuisine.isNotEmpty && city.isNotEmpty) {
                FocusScope.of(dialogContext).unfocus();
                final newRestaurant = RestaurantModel(
                  id: '',
                  name: name,
                  cuisine: cuisine,
                  city: city,
                  street: street,
                  rating: 0.0,
                  reviewCount: 0,
                );
                Navigator.pop(dialogContext);
                try {
                  await FirestoreService.addRestaurant(newRestaurant);
                  if (screenContext.mounted) {
                    ScaffoldMessenger.of(screenContext).showSnackBar(
                      const SnackBar(
                        content: Text('Restaurant added successfully!'),
                      ),
                    );
                  }
                } catch (_) {
                  if (screenContext.mounted) {
                    ScaffoldMessenger.of(screenContext).showSnackBar(
                      const SnackBar(
                        content: Text('Could not add the restaurant.'),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(
    BuildContext screenContext,
    RestaurantModel restaurant, {
    double? existingRating,
    String existingComment = '',
    bool? existingTipFair,
  }) {
    final isEditing = existingRating != null;
    double selectedRating = existingRating ?? 5.0;
    bool? selectedTipFair = existingTipFair;
    final commentController = TextEditingController(text: existingComment);
    bool isSubmitting = false;
    showDialog(
      context: screenContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            isEditing
                ? "Edit review for ${restaurant.name}"
                : "Rate ${restaurant.name}",
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("How many stars?"),
                Slider(
                  value: selectedRating,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: selectedRating.toString(),
                  onChanged: isSubmitting
                      ? null
                      : (value) => setDialogState(
                            () => selectedRating = value,
                          ),
                ),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Comment (optional)',
                    hintText: 'Share your experience at this location',
                  ),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Is the tip fair?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Yes, it is fair'),
                  value: true,
                  groupValue: selectedTipFair,
                  onChanged: isSubmitting
                      ? null
                      : (value) => setDialogState(
                            () => selectedTipFair = value,
                          ),
                ),
                RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('No, it is not fair'),
                  value: false,
                  groupValue: selectedTipFair,
                  onChanged: isSubmitting
                      ? null
                      : (value) => setDialogState(
                            () => selectedTipFair = value,
                          ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      Navigator.pop(dialogContext);
                      try {
                        final savedRating = isEditing
                            ? await FirestoreService.updateReview(
                                restaurant.id,
                                selectedRating,
                                comment: commentController.text,
                                tipFair: selectedTipFair,
                              )
                            : await FirestoreService.addReview(
                                restaurant.id,
                                selectedRating,
                                comment: commentController.text,
                                tipFair: selectedTipFair,
                              );
                        if (mounted) {
                          setState(() {
                            _savedRatings[restaurant.id] = savedRating;
                          });
                        }
                        if (screenContext.mounted) {
                          ScaffoldMessenger.of(screenContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing
                                    ? 'Review updated successfully!'
                                    : 'Review saved successfully!',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        final alreadyReviewed =
                            e.toString().contains("ALREADY_REVIEWED");
                        final reviewNotFound =
                            e.toString().contains("REVIEW_NOT_FOUND");
                        final errorMessage = switch (e) {
                          FirebaseException(:final code)
                              when code == 'permission-denied' =>
                            'Firebase denied the review. Deploy the updated Firestore rules.',
                          FirebaseException(:final code)
                              when code == 'unavailable' =>
                            'Firebase is unavailable. Check your connection and try again.',
                          FirebaseException(:final code)
                              when code == 'not-found' =>
                            'The restaurant could not be found. Refresh the list and try again.',
                          FirebaseException(:final code) =>
                            'Could not save the review (Firebase: $code).',
                          _ => 'Could not save the review. Please try again.',
                        };
                        if (screenContext.mounted) {
                          ScaffoldMessenger.of(screenContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                alreadyReviewed
                                    ? 'You have already reviewed this restaurant!'
                                    : reviewNotFound
                                        ? 'Your review could not be found. Please refresh and try again.'
                                        : errorMessage,
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow.shade50,
      appBar: AppBar(
        leadingWidth: 68,
        leading: const AppLogo(),
        title: const Text('Community Reviews'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRestaurantDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<RestaurantModel>>(
        stream: FirestoreService.getRestaurants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text("No restaurants added yet. Be the first!"));
          }

          final restaurants = snapshot.data!;
          return DraggableScrollbar(
            builder: (context, scrollController) => ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.only(right: 8),
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = restaurants[index];
                final savedRating = _savedRatings[restaurant.id];
                final displayedRating =
                    savedRating?.rating ?? restaurant.rating;
                final displayedReviewCount =
                    savedRating?.reviewCount ?? restaurant.reviewCount;
                return FutureBuilder<
                    ({double rating, String comment, bool? tipFair})?>(
                  future: FirestoreService.getUserReview(restaurant.id),
                  builder: (context, reviewSnapshot) {
                    final userReview = reviewSnapshot.data;
                    final existingRating = userReview?.rating;
                    final hasReviewed = existingRating != null;

                    return StreamBuilder<ReviewStats>(
                      stream: FirestoreService.getReviewStats(restaurant.id),
                      builder: (context, statsSnapshot) {
                        final stats = statsSnapshot.data ?? const ReviewStats();
                        return Card(
                          color: Colors.orange.shade50,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(
                              restaurant.name,
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: Colors.deepOrange.shade800,
                              ),
                            ),
                            subtitle: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: restaurant.cuisine,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: restaurant.city.isEmpty
                                        ? ''
                                        : '  •  ${restaurant.city}${restaurant.street.isEmpty ? '' : ', ${restaurant.street}'}',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  TextSpan(
                                    text:
                                        "  •  ⭐ ${displayedRating.toStringAsFixed(1)} ($displayedReviewCount reviews)",
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (stats.fairVotes + stats.unfairVotes > 0)
                                    TextSpan(
                                      text:
                                          '\n👍 ${stats.fairVotes} fair  •  👎 ${stats.unfairVotes} not fair',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  if (stats.comments.isNotEmpty)
                                    TextSpan(
                                      text:
                                          '\n💬 ${stats.comments.take(2).join('  •  ')}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                ],
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                hasReviewed
                                    ? Icons.edit_outlined
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 30,
                              ),
                              tooltip: hasReviewed
                                  ? 'Edit your review'
                                  : 'Add a review',
                              onPressed: hasReviewed
                                  ? () => _showRatingDialog(
                                        context,
                                        restaurant,
                                        existingRating: existingRating,
                                        existingComment:
                                            userReview?.comment ?? '',
                                        existingTipFair: userReview?.tipFair,
                                      )
                                  : () =>
                                      _showRatingDialog(context, restaurant),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRestaurantDialog(context),
        child: const Icon(Icons.restaurant),
      ),
    );
  }
}
