import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/listing_item.dart';

class MarketplaceService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- GENERIC LISTING STREAMS ---

  // Get items based on type (Product, Exchange, Promotion)
  static Stream<List<ListingItem>> streamListings(
    ListingType type, {
    String? category,
    bool isAdmin = false,
  }) {
    Query query = _db.collection(type.collectionName);

    // If it's Promotion, only show approved ones unless it's Admin viewing
    if (type == ListingType.promotion && !isAdmin) {
      query = query.where('isApproved', isEqualTo: true);
    }

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map(
            (doc) => ListingItem.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
              type,
            ),
          )
          .toList();
    });
  }

  // --- CREATE OPERATIONS ---

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

  static Future<void> createPromotion({
    required String businessName,
    required String description,
    required String category,
    String? website,
    String? location,
    required File? imageFile,
  }) async {
    await _createListing(
      type: ListingType.promotion,
      data: {
        'businessName': businessName,
        'description': description,
        'category': category,
        'website': website,
        'location': location,
        'isApproved': false, // Needs Admin Approval
      },
      imageFile: imageFile,
    );
  }

  // Helper to handle upload and DB write
  static Future<void> _createListing({
    required ListingType type,
    required Map<String, dynamic> data,
    required File? imageFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in');

    String? imageUrl;
    if (imageFile != null) {
      final ref = _storage.ref().child(
        '${type.collectionName}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }

    final finalData = {
      ...data,
      'imageUrl': imageUrl,
      'ownerId': user.uid,
      'ownerName': user.displayName ?? 'Student',
      'ownerEmail': user.email,
      'status': 'available',
      'views': 0,
      'favorites': 0,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _db.collection(type.collectionName).add(finalData);
  }

  // --- ADMIN OPERATIONS ---

  // Approve a business promotion
  static Future<void> approvePromotion(String id, bool isApproved) async {
    await _db.collection('promotions').doc(id).update({
      'isApproved': isApproved,
      'status': isApproved ? 'approved' : 'rejected',
    });
  }

  // Delete any item (for Admin or Owner)
  static Future<void> deleteItem(String id, ListingType type) async {
    await _db.collection(type.collectionName).doc(id).delete();
  }

  // Get System Stats for Admin Dashboard
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

  // --- REPORTING SYSTEM ---

  static Future<void> reportItem(
    String itemId,
    String itemType,
    String reason,
  ) async {
    await _db.collection('reports').add({
      'itemId': itemId,
      'itemType': itemType, // 'product', 'exchange', etc.
      'reason': reason,
      'reporterId': _auth.currentUser?.uid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
