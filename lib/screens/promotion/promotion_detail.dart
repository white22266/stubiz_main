import 'package:flutter/material.dart';

class PromotionDetail extends StatelessWidget {
  const PromotionDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 150, child: Placeholder()),
            const SizedBox(height: 12),
            const Text('Printing Service',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('Fast, cheap, reliable'),
            const Spacer(),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Chat Owner'),
            ),
          ],
        ),
      ),
    );
  }
}
