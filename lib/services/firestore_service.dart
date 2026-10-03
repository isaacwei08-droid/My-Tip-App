import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/receipt_model.dart';
import '../models/restaurant_model.dart';
import '../models/monthly_subscription_model.dart';

class ReviewStats {
  final List<String> comments;
  final int fairVotes;
  final int unfairVotes;

  const ReviewStats({
    this.comments = const [],
    this.fairVotes = 0,
    this.unfairVotes = 0,
  });
}

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = "receipts";
  static const String _restaurantsCollection = "restaurants";
  static const String _reviewsCollection = "reviews";
  static const String _userDataCollection = "user_data";
  static const String _subscriptionsCollection = "monthly_subscriptions";

  static Future<void> addReceipt(ReceiptModel receipt) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('NOT_AUTHENTICATED');
    await _db.collection(_collection).add({
      ...receipt.toMap(),
      'userId': user.uid,
    });
  }

  static Stream<List<ReceiptModel>> getReceipts() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(<ReceiptModel>[]);

    return _db
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ReceiptModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  static Future<void> deleteReceipt(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('NOT_AUTHENTICATED');
    final ref = _db.collection(_collection).doc(id);
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.data()?['userId'] != user.uid) {
      throw Exception('RECEIPT_NOT_FOUND');
    }
    await ref.delete();
  }

  static Future<void> updateReceipt(ReceiptModel receipt) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('NOT_AUTHENTICATED');
    final ref = _db.collection(_collection).doc(receipt.id);
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.data()?['userId'] != user.uid) {
      throw Exception('RECEIPT_NOT_FOUND');
    }
    await ref.update(receipt.toMap());
  }

  static Stream<double> getBudget(String userId) {
    return _db
        .collection(_userDataCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return (doc.data()!['budget'] as num).toDouble();
      }
      return 500.0; // Default budget
    });
  }

  static Future<void> updateBudget(String userId, double newBudget) async {
    await _db.collection(_userDataCollection).doc(userId).set({
      'budget': newBudget,
    }, SetOptions(merge: true));
  }

  static CollectionReference<Map<String, dynamic>> _subscriptions(
    String userId,
  ) {
    return _db
        .collection(_userDataCollection)
        .doc(userId)
        .collection(_subscriptionsCollection);
  }

  static Stream<List<MonthlySubscriptionModel>> getMonthlySubscriptions(
    String userId,
  ) {
    return _subscriptions(userId).orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => MonthlySubscriptionModel.fromMap(doc.id, doc.data()),
          )
          .toList();
    });
  }

  static Future<void> addMonthlySubscription(
    String userId,
    String name,
    double amount,
  ) async {
    await _subscriptions(userId).add({
      'name': name,
      'amount': amount,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteMonthlySubscription(
    String userId,
    String subscriptionId,
  ) async {
    await _subscriptions(userId).doc(subscriptionId).delete();
  }

  // Restaurant methods
  static Future<void> addRestaurant(RestaurantModel restaurant) async {
    await _db.collection(_restaurantsCollection).add(restaurant.toMap());
  }

  static Stream<List<RestaurantModel>> getRestaurants() {
    return _db.collection(_restaurantsCollection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return RestaurantModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  static Future<void> updateRestaurantRating(
      String id, double newRating, int newReviewCount) async {
    await _db.collection(_restaurantsCollection).doc(id).update({
      'rating': newRating,
      'reviewCount': newReviewCount,
    });
  }

  // Reviews
  static Future<bool> hasUserReviewed(String restaurantId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await _db
        .collection(_reviewsCollection)
        .doc("${user.uid}_$restaurantId")
        .get();
    return doc.exists;
  }

  static Future<double?> getUserReviewRating(String restaurantId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await _db
        .collection(_reviewsCollection)
        .doc("${user.uid}_$restaurantId")
        .get();
    if (!doc.exists) return null;
    return (doc.data()?['rating'] as num?)?.toDouble();
  }

  static Future<({double rating, String comment, bool? tipFair})?>
      getUserReview(String restaurantId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await _db
        .collection(_reviewsCollection)
        .doc('${user.uid}_$restaurantId')
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return (
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      comment: data['comment'] as String? ?? '',
      tipFair: data['tipFair'] as bool?,
    );
  }

  static Stream<ReviewStats> getReviewStats(String restaurantId) {
    return _db
        .collection(_reviewsCollection)
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
      final comments = <String>[];
      var fairVotes = 0;
      var unfairVotes = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final comment = (data['comment'] as String?)?.trim() ?? '';
        if (comment.isNotEmpty) comments.add(comment);
        if (data['tipFair'] == true) {
          fairVotes++;
        } else if (data['tipFair'] == false) {
          unfairVotes++;
        }
      }
      return ReviewStats(
        comments: comments,
        fairVotes: fairVotes,
        unfairVotes: unfairVotes,
      );
    });
  }

  static Future<({double rating, int reviewCount})> addReview(
      String restaurantId, double rating,
      {String comment = '', bool? tipFair}) async {
    print(
        'FirestoreService: Adding review for $restaurantId with rating $rating');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('FirestoreService: User not authenticated');
      throw Exception("NOT_AUTHENTICATED");
    }
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Must be between 1 and 5');
    }

    final restaurantRef =
        _db.collection(_restaurantsCollection).doc(restaurantId);
    final reviewRef =
        _db.collection(_reviewsCollection).doc("${user.uid}_$restaurantId");

    try {
      print('FirestoreService: Checking for existing review...');
      final existingReview = await reviewRef.get();
      if (existingReview.exists) {
        print('FirestoreService: Already reviewed');
        throw Exception("ALREADY_REVIEWED");
      }
    } catch (e) {
      print('FirestoreService: Error checking existing review: $e');
      rethrow;
    }

    print('FirestoreService: Starting transaction...');
    return _db.runTransaction((transaction) async {
      final restaurantDoc = await transaction.get(restaurantRef);
      if (!restaurantDoc.exists) {
        throw Exception("RESTAURANT_NOT_FOUND");
      }

      final data = restaurantDoc.data()!;
      final double oldRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
      final int oldCount = data['reviewCount'] as int? ?? 0;

      final double newTotalRating = (oldRating * oldCount) + rating;
      final int newCount = oldCount + 1;
      final double newAverage = newTotalRating / newCount;

      transaction.set(reviewRef, {
        'userId': user.uid,
        'restaurantId': restaurantId,
        'rating': rating,
        'comment': comment.trim(),
        'tipFair': tipFair,
        'timestamp': FieldValue.serverTimestamp(),
      });

      transaction.set(
        restaurantRef,
        {
          'rating': newAverage,
          'reviewCount': newCount,
        },
        SetOptions(merge: true),
      );

      return (rating: newAverage, reviewCount: newCount);
    }).then((value) {
      print('FirestoreService: Transaction successful');
      return value;
    }).catchError((error) {
      print('FirestoreService: Transaction failed: $error');
      throw error;
    });
  }

  static Future<({double rating, int reviewCount})> updateReview(
      String restaurantId, double newRating,
      {String comment = '', bool? tipFair}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("NOT_AUTHENTICATED");
    if (newRating < 1 || newRating > 5) {
      throw ArgumentError.value(
        newRating,
        'rating',
        'Must be between 1 and 5',
      );
    }

    final restaurantRef =
        _db.collection(_restaurantsCollection).doc(restaurantId);
    final reviewRef =
        _db.collection(_reviewsCollection).doc("${user.uid}_$restaurantId");

    return _db.runTransaction((transaction) async {
      final reviewDoc = await transaction.get(reviewRef);
      final restaurantDoc = await transaction.get(restaurantRef);
      if (!reviewDoc.exists) throw Exception("REVIEW_NOT_FOUND");
      if (!restaurantDoc.exists) throw Exception("RESTAURANT_NOT_FOUND");

      final oldRating = (reviewDoc.data()?['rating'] as num?)?.toDouble() ?? 0;
      final data = restaurantDoc.data()!;
      final oldAverage = (data['rating'] as num?)?.toDouble() ?? 0;
      final count = (data['reviewCount'] as num?)?.toInt() ?? 1;
      final newAverage = count > 0
          ? ((oldAverage * count) - oldRating + newRating) / count
          : newRating;

      transaction.set(
          reviewRef,
          {
            'rating': newRating,
            'comment': comment.trim(),
            'tipFair': tipFair,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
      transaction.set(
        restaurantRef,
        {'rating': newAverage, 'reviewCount': count},
        SetOptions(merge: true),
      );

      return (rating: newAverage, reviewCount: count);
    });
  }
}
