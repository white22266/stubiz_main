import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingType { product, exchange, promotion }

extension ListingTypeExtension on ListingType {
  String get value {
    switch (this) {
      case ListingType.product:
        return 'product';
      case ListingType.exchange:
        return 'exchange';
      case ListingType.promotion:
        return 'promotion';
    }
  }

  String get collectionName {
    switch (this) {
      case ListingType.product:
        return 'products';
      case ListingType.exchange:
        return 'exchange_posts';
      case ListingType.promotion:
        return 'promotions';
    }
  }

  String get displayName {
    switch (this) {
      case ListingType.product:
        return 'Product';
      case ListingType.exchange:
        return 'Exchange';
      case ListingType.promotion:
        return 'Promotion';
    }
  }
}

class ListingItem {
  final String id;
  final ListingType type;

  // Common Fields
  final String name; // Product Name / Exchange Title / Business Name
  final String description;
  final String category;
  final String? imageUrl;
  final List<String> imageUrls;
  final String contactInfo;

  // Owner Info
  final String ownerId;
  final String ownerName;
  final String ownerEmail;

  // Status
  final String status; // available, sold, exchanged, pending
  final int views;
  final int favorites;

  // Specific Fields
  final double? price; // For Product
  final String? wantedItem; // For Exchange
  final String? website; // For Promotion
  final String? location; // For Promotion
  final GeoPoint? geo; // coordinates
  final bool isApproved; // For Promotion (Admin control)

  final DateTime? createdAt;

  // Local state
  bool isFavorite;

  ListingItem({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.category,
    this.imageUrl,
    this.imageUrls = const [],
    required this.contactInfo,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    this.status = 'available',
    this.views = 0,
    this.favorites = 0,
    this.price,
    this.wantedItem,
    this.website,
    this.location,
    this.geo,
    this.isApproved = false,
    this.createdAt,
    this.isFavorite = false,
  });

  factory ListingItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    ListingType type,
  ) {
    final data = doc.data() ?? {};

    // Name handling based on type
    String extractedName = '';
    if (type == ListingType.product) {
      extractedName = data['name'] ?? '';
    } else if (type == ListingType.exchange) {
      extractedName = data['title'] ?? '';
    } else if (type == ListingType.promotion) {
      extractedName = data['businessName'] ?? '';
    }

    return ListingItem(
      id: doc.id,
      type: type,
      name: extractedName.toString(),
      description: (data['description'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      imageUrl: data['imageUrl'] as String?,
      imageUrls: (data['imageUrls'] is List)
          ? List<String>.from(data['imageUrls'])
          : [],
      contactInfo: (data['contactInfo'] ?? '').toString(),
      ownerId: (data['ownerId'] ?? '').toString(),
      ownerName: (data['ownerName'] ?? '').toString(),
      ownerEmail: (data['ownerEmail'] ?? '').toString(),
      status: (data['status'] ?? 'available').toString(),
      views: (data['views'] ?? 0) as int,
      favorites: (data['favorites'] ?? 0) as int,
      price: data['price'] is num ? (data['price'] as num).toDouble() : null,
      wantedItem: data['wantedItem'] as String?,
      website: data['website'] as String?,
      location: data['location'] as String?,
      geo: data['geo'] is GeoPoint ? data['geo'] as GeoPoint : null,
      isApproved: data['isApproved'] == true,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  String get displayPrice =>
      price != null ? 'RM ${price!.toStringAsFixed(2)}' : 'Free';

  String get timeAgo {
    final dt = createdAt;
    if (dt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays >= 365) {
      final years = (diff.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
    if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    }
    return 'Just now';
  }

  bool get isAvailable {
    final s = status.toLowerCase().trim();
    // treat these as not available
    return !(s == 'sold' ||
        s == 'exchanged' ||
        s == 'completed' ||
        s == 'unavailable' ||
        s == 'inactive');
  }

  String get statusDisplayText {
    final s = status.trim();
    if (s.isEmpty) return 'Available';

    switch (s.toLowerCase()) {
      case 'available':
        return 'Available';
      case 'sold':
        return 'Sold';
      case 'exchanged':
        return 'Exchanged';
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      default:
        // Capitalize first letter
        return s[0].toUpperCase() + s.substring(1);
    }
  }
}

class ReportItem {
  final String id;
  final String itemId;
  final String itemType; // 'product', 'exchange', 'promotion'
  final String reason;
  final String status; // 'pending', 'resolved'
  final DateTime? createdAt;

  ReportItem({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.reason,
    required this.status,
    this.createdAt,
  });

  factory ReportItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ReportItem(
      id: doc.id,
      itemId: (data['itemId'] ?? '').toString(),
      itemType: (data['itemType'] ?? '').toString(),
      reason: (data['reason'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}
