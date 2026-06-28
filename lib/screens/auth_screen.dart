import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  final bool isFromBackground;

  const AuthScreen({super.key, this.isFromBackground = false});

  // Track if this screen is currently in the widget tree
  static bool isAuthScreenVisible = false;
  // Track the exact timestamp of successful authentication to prevent immediate re-locking
  static DateTime? lastSuccessTime;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _authorized = 'غير مصرح';

  @override
  void initState() {
    super.initState();
    AuthScreen.isAuthScreenVisible = true;
    _authenticate();
  }

  @override
  void dispose() {
    AuthScreen.isAuthScreenVisible = false;
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'جاري التحقق...';
      });
      authenticated = await auth.authenticate(
        localizedReason: 'يرجى التحقق من هويتك لفتح التطبيق',
        persistAcrossBackgrounding: true,
        biometricOnly: true,
      );
    } on PlatformException catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authorized = 'فشل التحقق: ${e.message}';
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      _isAuthenticating = false;
    });

    if (authenticated) {
      AuthScreen.lastSuccessTime = DateTime.now();
      if (widget.isFromBackground) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      setState(() {
        _authorized = 'تم إلغاء التحقق';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 100, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'التطبيق مقفل',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_authorized),
            const SizedBox(height: 32),
            if (!_isAuthenticating)
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint),
                label: const Text('المحاولة مرة أخرى'),
              )
            else
              const CircularProgressIndicator(),
          ],
        ),
      ),
    ),
    );
  }
}
