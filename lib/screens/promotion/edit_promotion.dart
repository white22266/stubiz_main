import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../models/listing_item.dart';
import '../../services/marketplace_service.dart';

class EditPromotionScreen extends StatefulWidget {
  final ListingItem promotion;

  const EditPromotionScreen({super.key, required this.promotion});

  @override
  State<EditPromotionScreen> createState() => _EditPromotionScreenState();
}

class _EditPromotionScreenState extends State<EditPromotionScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _businessName;
  late String _desc;
  late String _category;
  String? _website;

  final _locationCtrl = TextEditingController();
  File? _imageFile;

  double? _lat;
  double? _lng;

  bool _isLoading = false;

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
  void initState() {
    super.initState();
    _businessName = widget.promotion.name;
    _desc = widget.promotion.description;
    _category = widget.promotion.category;
    _website = widget.promotion.website;
    _locationCtrl.text = widget.promotion.location ?? '';

    if (widget.promotion.geo != null) {
      _lat = widget.promotion.geo!.latitude;
      _lng = widget.promotion.geo!.longitude;
    }
  }

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location found: $_lat, $_lng'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Geocoding error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      GeoPoint? geo;
      if (_lat != null && _lng != null) {
        geo = GeoPoint(_lat!, _lng!);
      }

      await MarketplaceService.updatePromotion(
        promotionId: widget.promotion.id,
        businessName: _businessName,
        description: _desc,
        category: _category,
        website: _website,
        locationText: _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
        geo: geo,
        imageFile: _imageFile,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promotion updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Business Promotion')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : widget.promotion.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Image.network(
                                widget.promotion.imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                              Container(
                                color: Colors.black.withValues(alpha: 0.3),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Tap to change photo',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 40),
                            SizedBox(height: 8),
                            Text('Tap to add photo'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                initialValue: _businessName,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _businessName = v!,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _desc,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _desc = v!,
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _website,
                decoration: const InputDecoration(
                  labelText: 'Website (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                onSaved: (v) => _website = v!.isEmpty ? null : v,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationCtrl,
                decoration: InputDecoration(
                  labelText: 'Location/Address (optional)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _geocodeAddress,
                    tooltip: 'Geocode Address',
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (_lat != null && _lng != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Coordinates: $_lat, $_lng',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Updating...' : 'Update Promotion'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
