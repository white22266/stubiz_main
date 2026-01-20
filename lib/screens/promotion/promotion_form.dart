// lib/screens/promotion/promotion_form.dart
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../services/marketplace_service.dart';

class PromotionForm extends StatefulWidget {
  const PromotionForm({super.key});

  @override
  State<PromotionForm> createState() => _PromotionFormState();
}

class _PromotionFormState extends State<PromotionForm> {
  final _formKey = GlobalKey<FormState>();

  String _businessName = '';
  String _desc = '';
  String _category = 'Food & Beverage';
  String? _website;

  final _locationCtrl = TextEditingController();
  File? _imageFile;

  double? _lat;
  double? _lng;

  bool _isLoading = false;

  // Replace with your key (Google Maps Platform -> Geocoding API enabled).
  static const String _googleGeocodingApiKey =
      'AIzaSyD68kaeLbyWrUEpNMvqk8lFdy5hxfpUG3o';

  final List<String> _categories = [
    'Food & Beverage',
    'Services',
    'Tutoring',
    'Handmade',
    'Others',
  ];

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _geocodeAddress() async {
    final address = _locationCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an address/location first.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final encoded = Uri.encodeComponent(address);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=$encoded&key=$_googleGeocodingApiKey',
      );

      final resp = await http.get(url);
      if (resp.statusCode != 200) {
        throw Exception('Geocoding request failed (${resp.statusCode}).');
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final status = (data['status'] as String?) ?? 'UNKNOWN';
      if (status != 'OK') {
        final msg = (data['error_message'] as String?) ?? '';
        throw Exception(
          'Geocoding status: $status ${msg.isNotEmpty ? "- $msg" : ""}',
        );
      }

      final results = (data['results'] as List<dynamic>);
      if (results.isEmpty) {
        throw Exception('No geocoding results.');
      }

      final loc = results.first['geometry']['location'] as Map<String, dynamic>;
      setState(() {
        _lat = (loc['lat'] as num).toDouble();
        _lng = (loc['lng'] as num).toDouble();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location generated via Geocoding API.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Geocoding error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _useMyLocation() async {
    setState(() => _isLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission denied forever. Please enable it in settings.',
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Using current location (permission).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Location error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final locationText = _locationCtrl.text.trim().isEmpty
        ? null
        : _locationCtrl.text.trim();

    setState(() => _isLoading = true);
    try {
      await MarketplaceService.createPromotion(
        businessName: _businessName,
        description: _desc,
        category: _category,
        website: _website,
        locationText: locationText,
        geo: (_lat != null && _lng != null) ? GeoPoint(_lat!, _lng!) : null,
        imageFile: _imageFile,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Submission Received'),
          content: const Text(
            'Your promotion has been submitted and is pending Admin approval. It will appear once approved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submit error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _coordsBox() {
    if (_lat == null || _lng == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('Latitude: $_lat\nLongitude: $_lng'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promote Business')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    border: Border.all(
                      color: Colors.purple.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_business,
                              size: 40,
                              color: Colors.purple,
                            ),
                            SizedBox(height: 6),
                            Text('Add Business Logo/Banner'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                onSaved: (v) => _businessName = v!.trim(),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField(
                initialValue: _category,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v.toString()),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description (Services, Hours, etc.)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                onSaved: (v) => _desc = v!.trim(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location / Address (e.g., UTHM Parit Raja)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _geocodeAddress,
                      icon: const Icon(Icons.public),
                      label: const Text('Generate (API)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _useMyLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use My Location'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _coordsBox(),
              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Website / Instagram Link (Optional)',
                  border: OutlineInputBorder(),
                ),
                onSaved: (v) => _website = (v == null || v.trim().isEmpty)
                    ? null
                    : v.trim(),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit for Approval'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
