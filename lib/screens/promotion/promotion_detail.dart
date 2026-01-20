// lib/screens/promotion/promotion_detail.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/listing_item.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../chat/chat_room.dart';

class PromotionDetailScreen extends StatefulWidget {
  final ListingItem item;
  const PromotionDetailScreen({super.key, required this.item});

  @override
  State<PromotionDetailScreen> createState() => _PromotionDetailScreenState();
}

class _PromotionDetailScreenState extends State<PromotionDetailScreen> {
  GoogleMapController? _mapController;

  MapType _mapType = MapType.normal;
  LatLng? _promoPos;
  Set<Marker> _markers = const {};

  static const double _defaultZoom = 16;

  @override
  void initState() {
    super.initState();
    _initMapData();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  void _initMapData() {
    final GeoPoint? geo = widget.item.geo;
    if (geo == null) return;

    final pos = LatLng(geo.latitude, geo.longitude);
    _promoPos = pos;

    _markers = {
      Marker(
        markerId: const MarkerId('promo_location'),
        position: pos,
        infoWindow: InfoWindow(
          title: widget.item.name,
          snippet: widget.item.location ?? 'Promotion location',
        ),
      ),
    };
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Optional: if you want to ensure camera is correct after map loads
    if (_promoPos != null) {
      _animateTo(_promoPos!, zoom: _defaultZoom);
    }
  }

  Future<void> _animateTo(LatLng target, {double? zoom}) async {
    if (_mapController == null) return;

    final camera = CameraPosition(target: target, zoom: zoom ?? _defaultZoom);
    await _mapController!.animateCamera(CameraUpdate.newCameraPosition(camera));
  }

  void _recenter() {
    final pos = _promoPos;
    if (pos == null) return;
    _animateTo(pos, zoom: _defaultZoom);
  }

  Future<void> _zoomIn() async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(CameraUpdate.zoomOut());
  }

  void _toggleMapType() {
    setState(() {
      _mapType = _mapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
  }

  Future<void> _openInMaps(BuildContext context) async {
    final GeoPoint? geo = widget.item.geo;
    if (geo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No coordinates available.')),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${geo.latitude},${geo.longitude}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  Future<void> _openDirections(BuildContext context) async {
    final GeoPoint? geo = widget.item.geo;
    if (geo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No coordinates available.')),
      );
      return;
    }

    // Works on Android (Google Maps) and iOS if user has Google Maps installed.
    // If not installed, it usually falls back to browser.
    final uri = Uri.parse(
      'google.navigation:q=${geo.latitude},${geo.longitude}&mode=d',
    );

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      // Fallback to web directions
      final fallback = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${geo.latitude},${geo.longitude}&travelmode=driving',
      );
      final ok2 = await launchUrl(
        fallback,
        mode: LaunchMode.externalApplication,
      );
      if (!ok2 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open navigation.')),
        );
      }
    }
  }

  Future<void> _contactOwner(BuildContext context) async {
    final user = AuthService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login required')));
      return;
    }

    try {
      final chatId = await ChatService.startChat(
        widget.item.ownerId,
        widget.item.ownerName,
      );
      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            chatId: chatId,
            otherUserId: widget.item.ownerId,
            otherUserName: widget.item.ownerName,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _mapSection(BuildContext context) {
    if (_promoPos == null) return const SizedBox.shrink();

    final pos = _promoPos!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Location Map',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 240,
            width: double.infinity,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: pos,
                    zoom: _defaultZoom,
                  ),
                  mapType: _mapType,
                  markers: _markers,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: _onMapCreated,
                ),

                // Map controls (top-right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Column(
                    children: [
                      _miniFab(
                        icon: Icons.layers,
                        tooltip: 'Toggle Map Type',
                        onTap: _toggleMapType,
                      ),
                      const SizedBox(height: 10),
                      _miniFab(
                        icon: Icons.add,
                        tooltip: 'Zoom In',
                        onTap: _zoomIn,
                      ),
                      const SizedBox(height: 10),
                      _miniFab(
                        icon: Icons.remove,
                        tooltip: 'Zoom Out',
                        onTap: _zoomOut,
                      ),
                      const SizedBox(height: 10),
                      _miniFab(
                        icon: Icons.my_location,
                        tooltip: 'Re-center',
                        onTap: _recenter,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openInMaps(context),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open in Google Maps'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openDirections(context),
                icon: const Icon(Icons.directions),
                label: const Text('Directions'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _miniFab({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Tooltip(message: tooltip, child: Icon(icon)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl != null)
              Image.network(
                item.imageUrl!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (item.location != null)
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(item.location!),
                      contentPadding: EdgeInsets.zero,
                    ),

                  _mapSection(context),

                  if (item.website != null)
                    ListTile(
                      leading: const Icon(Icons.link),
                      title: Text(item.website!),
                      contentPadding: EdgeInsets.zero,
                    ),

                  const Divider(),
                  const Text(
                    'About Us',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Owner',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text(item.ownerName, style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: () => _contactOwner(context),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Contact Business'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}
