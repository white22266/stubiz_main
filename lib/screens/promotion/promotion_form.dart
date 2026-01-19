import 'dart:io';
import 'package:flutter/material.dart';
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
  String? _location;
  File? _imageFile;
  bool _isLoading = false;

  final List<String> _categories = [
    'Food & Beverage',
    'Services',
    'Tutoring',
    'Handmade',
    'Others',
  ];

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      await MarketplaceService.createPromotion(
        businessName: _businessName,
        description: _desc,
        category: _category,
        website: _website,
        location: _location,
        imageFile: _imageFile,
      );

      if (!mounted) return;
      // Show Approval Alert
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_business,
                              size: 40,
                              color: Colors.purple,
                            ),
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
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _businessName = v!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField(
                value: _category,
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
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _desc = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Location (e.g., G3 Library)',
                  border: OutlineInputBorder(),
                ),
                onSaved: (v) => _location = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Website / Instagram Link (Optional)',
                  border: OutlineInputBorder(),
                ),
                onSaved: (v) => _website = v,
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
                      ? const CircularProgressIndicator(color: Colors.white)
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
