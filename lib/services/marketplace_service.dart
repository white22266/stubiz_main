// lib/services/marketplace_service.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/listing_item.dart';
import 'auth_service.dart';

class MarketplaceService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // -------------------- GENERIC LISTING STREAMS --------------------

  static Stream<List<ListingItem>> streamListings(
    ListingType type, {
    String? category,
    bool isAdmin = false,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(type.collectionName);

    // Promotions: only show approved items to students
    if (type == ListingType.promotion && !isAdmin) {
      query = query.where('isApproved', isEqualTo: true);
    }

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((snap) {
      return snap.docs
          .map((doc) => ListingItem.fromFirestore(doc, type))
          .toList();
    });
  }

  static Future<ListingItem?> getListingById(
    ListingType type,
    String id,
  ) async {
    final doc = await _db.collection(type.collectionName).doc(id).get();
    if (!doc.exists) return null;
    return ListingItem.fromFirestore(doc, type);
  }

  // -------------------- CREATE OPERATIONS --------------------

  static Future<void> createProduct({
    required String name,
    required double price,
    required String description,
    required String category,
    required File? imageFile,
  }) async {
    await _createListing(
      type: ListingType.product,
      data: {
        'name': name,
        'price': price,
        'description': description,
        'category': category,
      },
      imageFile: imageFile,
    );
  }

  static Future<void> createExchange({
    required String title,
    required String wantedItem,
    required String description,
    required String category,
    required File? imageFile,
  }) async {
    await _createListing(
      type: ListingType.exchange,
      data: {
        'title': title,
        'wantedItem': wantedItem,
        'description': description,
        'category': category,
      },
      imageFile: imageFile,
    );
  }

  // Promotion: supports location text + GeoPoint (lat/lng) for your API requirement
  static Future<void> createPromotion({
    required String businessName,
    required String description,
    required String category,
    String? website,
    String? locationText,
    GeoPoint? geo,
    File? imageFile,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception('Must be logged in');
    }

    await _createListing(
      type: ListingType.promotion,
      data: {
        'businessName': businessName,
        'description': description,
        'category': category,
        'website': (website != null && website.trim().isNotEmpty)
            ? website.trim()
            : null,
        'location': (locationText != null && locationText.trim().isNotEmpty)
            ? locationText.trim()
            : null,

        // IMPORTANT for rubric: store coordinates (from Geocoding API or GPS permission)
        'geo': geo,

        // approval flow
        'isApproved': false,
        'status': 'pending',
      },
      imageFile: imageFile,
    );
  }

  // -------------------- INTERNAL HELPER --------------------

  static Future<void> _createListing({
    required ListingType type,
    required Map<String, dynamic> data,
    required File? imageFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in');

    String? imageUrl;
    String? imagePath;

    if (imageFile != null) {
      imagePath =
          '${type.collectionName}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(imagePath);
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }

    final finalData = <String, dynamic>{
      ...data,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'ownerId': user.uid,
      'ownerName': user.displayName ?? 'Student',
      'ownerEmail': user.email,
      'views': 0,
      'favorites': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // keep Firestore clean
    finalData.removeWhere((k, v) => v == null);

    await _db.collection(type.collectionName).add(finalData);
  }

  // -------------------- UPDATE OPERATIONS --------------------

  static Future<void> updateProduct({
    required String productId,
    required String name,
    required double price,
    required String description,
    required String category,
    File? imageFile,
  }) async {
    await _updateListing(
      type: ListingType.product,
      id: productId,
      data: {
        'name': name,
        'price': price,
        'description': description,
        'category': category,
      },
      imageFile: imageFile,
    );
  }

  static Future<void> updateExchange({
    required String exchangeId,
    required String title,
    required String wantedItem,
    required String description,
    required String category,
    File? imageFile,
  }) async {
    await _updateListing(
      type: ListingType.exchange,
      id: exchangeId,
      data: {
        'title': title,
        'wantedItem': wantedItem,
        'description': description,
        'category': category,
      },
      imageFile: imageFile,
    );
  }

  static Future<void> updatePromotion({
    required String promotionId,
    required String businessName,
    required String description,
    required String category,
    String? website,
    String? locationText,
    GeoPoint? geo,
    File? imageFile,
  }) async {
    await _updateListing(
      type: ListingType.promotion,
      id: promotionId,
      data: {
        'businessName': businessName,
        'description': description,
        'category': category,
        'website': website,
        'locationText': locationText,
        'geo': geo,
      },
      imageFile: imageFile,
    );
  }

  static Future<void> _updateListing({
    required ListingType type,
    required String id,
    required Map<String, dynamic> data,
    File? imageFile,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Upload new image if provided
    String? imageUrl;
    String? imagePath;

    if (imageFile != null) {
      final ext = imageFile.path.split('.').last;
      imagePath = '${type.collectionName}/$id.$ext';
      final ref = _storage.ref().child(imagePath);
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();

      // Delete old image if exists
      try {
        final doc = await _db.collection(type.collectionName).doc(id).get();
        final oldImagePath = doc.data()?['imagePath'] as String?;
        if (oldImagePath != null && oldImagePath != imagePath) {
          await _storage.ref().child(oldImagePath).delete();
        }
      } catch (_) {
        // Ignore if old image doesn't exist
      }
    }

    final updateData = {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (imageUrl != null) {
      updateData['imageUrl'] = imageUrl;
      updateData['imagePath'] = imagePath;
    }

    // Remove null values
    updateData.removeWhere((k, v) => v == null);

    await _db.collection(type.collectionName).doc(id).update(updateData);
  }

  // -------------------- ADMIN OPERATIONS --------------------

  static Future<void> approvePromotion(String id, bool isApproved) async {
    // ensure it targets the same collection as ListingType.promotion
    await _db.collection(ListingType.promotion.collectionName).doc(id).update({
      'isApproved': isApproved,
      'status': isApproved ? 'approved' : 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteItem(String id, ListingType type) async {
    // Optional: delete image from storage too
    final doc = await _db.collection(type.collectionName).doc(id).get();
    final data = doc.data(); // Map<String, dynamic>?
    final imagePath = data?['imagePath'] as String?;

    await _db.collection(type.collectionName).doc(id).delete();

    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        await _storage.ref().child(imagePath).delete();
      } catch (_) {
        // ignore (file may not exist)
      }
    }
  }

  static Future<Map<String, int>> getAdminStats() async {
    final products = await _db.collection('products').count().get();
    final exchanges = await _db.collection('exchange_posts').count().get();
    final promotions = await _db.collection('promotions').count().get();
    final users = await _db.collection('users').count().get();

    return {
      'products': products.count ?? 0,
      'exchanges': exchanges.count ?? 0,
      'promotions': promotions.count ?? 0,
      'users': users.count ?? 0,
    };
  }

  // -------------------- REPORTING SYSTEM --------------------

  static Future<void> reportItem(
    String itemId,
    String itemType,
    String reason,
  ) async {
    await _db.collection('reports').add({
      'itemId': itemId,
      'itemType': itemType,
      'reason': reason,
      'reporterId': _auth.currentUser?.uid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
