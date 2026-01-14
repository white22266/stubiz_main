import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_page.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool loading = false;
  String message =
      'We sent an activation email. Verify it, then press Continue.';

  Future<void> _continue() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final verified = await AuthService.reloadAndCheckEmailVerified();
      if (verified) {
        await AuthService.logout(); // force login again after activation
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
        return;
      }

      setState(() {
        message = 'Not verified yet. Please verify your email and try again.';
      });
    } catch (e) {
      setState(() => message = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      await AuthService.resendActivationEmail();
      setState(() => message = 'Activation email resent.');
    } catch (e) {
      setState(() => message = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activate Account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(message),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : _continue,
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: loading ? null : _resend,
              child: const Text('Resend Activation Email'),
            ),
          ],
        ),
      ),
    );
  }
}
