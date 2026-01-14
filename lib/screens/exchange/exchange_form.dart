import 'package:flutter/material.dart';
import '../../models/exchange_item.dart';

class ExchangeForm extends StatefulWidget {
  final ExchangeItem? item;

  const ExchangeForm({super.key, this.item});

  @override
  State<ExchangeForm> createState() => _ExchangeFormState();
}

class _ExchangeFormState extends State<ExchangeForm> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final wantedCtrl = TextEditingController();

  final categories = ['Books', 'Electronics', 'Stationery', 'Others'];
  String selectedCategory = 'Books';

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      titleCtrl.text = widget.item!.title;
      descCtrl.text = widget.item!.description;
      wantedCtrl.text = widget.item!.wantedItem;
      selectedCategory = widget.item!.category;
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    wantedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Exchange' : 'Add Exchange'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              items: categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => selectedCategory = value!);
              },
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: wantedCtrl,
              decoration:
                  const InputDecoration(labelText: 'Wanted Item'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: Text(isEdit ? 'Update' : 'Post'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (titleCtrl.text.isEmpty ||
        wantedCtrl.text.isEmpty ||
        descCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final item = ExchangeItem(
      id: widget.item?.id ?? DateTime.now().toString(),
      title: titleCtrl.text,
      description: descCtrl.text,
      wantedItem: wantedCtrl.text,
      category: selectedCategory,
    );

    Navigator.pop(context, item);
  }
}
