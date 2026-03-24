import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:fedispace/core/loops_auth.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';

/// Premium Loops login page with cyberpunk glassmorphism styling.
class LoopsLoginPage extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final VoidCallback onSkip;

  const LoopsLoginPage({
    Key? key,
    required this.onAuthenticated,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<LoopsLoginPage> createState() => _LoopsLoginPageState();
}

class _LoopsLoginPageState extends State<LoopsLoginPage>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String? _error;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _startOAuthFlow() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('[LOOPS AUTH] Step 1: Registering app...');
      final creds = await LoopsAuth.registerApp();
      final clientId = creds['client_id']!;
      debugPrint('[LOOPS AUTH] Step 2: Got client_id: $clientId');

      final authUrl = LoopsAuth.getAuthorizationUrl(clientId);
      debugPrint('[LOOPS AUTH] Step 3: Auth URL: $authUrl');

      debugPrint('[LOOPS AUTH] Step 4: Opening FlutterWebAuth2...');
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: 'space.echelon4.fedispace',
        options: const FlutterWebAuth2Options(
          timeout: 120,
          preferEphemeral: true,
        ),
      );
      debugPrint('[LOOPS AUTH] Step 5: Got callback result: $result');

      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      debugPrint('[LOOPS AUTH] Step 6: code=$code error=$error');

      if (error != null) {
        setState(() => _error = 'Authorization denied: $error');
      } else if (code != null && code.isNotEmpty) {
        debugPrint('[LOOPS AUTH] Step 7: Exchanging code for token...');
        await LoopsAuth.exchangeCode(code);
        debugPrint('[LOOPS AUTH] Step 8: Token exchange complete!');
        widget.onAuthenticated();
      } else {
        debugPrint('[LOOPS AUTH] Step 6b: No code in callback URL');
        setState(() => _error = 'Authorization failed - no code received. URL: $result');
      }
    } catch (e, stackTrace) {
      debugPrint('[LOOPS AUTH] ERROR: $e');
      debugPrint('[LOOPS AUTH] STACK: $stackTrace');
      if (mounted) {
        setState(() => _error = 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      body: Stack(
        children: [
          // Animated particle background
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _StarfieldPainter(_particleController.value),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    // Loops logo/icon with neon glow
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                CyberpunkTheme.neonPink.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CyberpunkTheme.neonPink
                                    .withOpacity(0.3 * _pulseAnimation.value),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.slow_motion_video_rounded,
                            size: 64,
                            color: CyberpunkTheme.neonPink,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Title with neon glow
                    Text(
                      'Connect to Loops',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: CyberpunkTheme.neonCyan.withOpacity(0.6),
                            blurRadius: 20,
                          ),
                          Shadow(
                            color: CyberpunkTheme.neonCyan.withOpacity(0.3),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Sign in to watch, like and share short videos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: CyberpunkTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Glassmorphism card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: CyberpunkTheme.glassBorder,
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: CyberpunkTheme.neonPink.withOpacity(0.05),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Sign in button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _startOAuthFlow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CyberpunkTheme.neonPink,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.slow_motion_video_rounded,
                                            size: 22),
                                        SizedBox(width: 10),
                                        Text(
                                          'Sign in with Loops',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Browse without account
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : widget.onSkip,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color:
                                      CyberpunkTheme.textTertiary.withOpacity(0.5),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Browse without account',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: CyberpunkTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),

                          // Error message
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFFF4757),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Powered by text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Powered by ',
                          style: TextStyle(
                            fontSize: 12,
                            color: CyberpunkTheme.textTertiary,
                          ),
                        ),
                        Text(
                          'loops.video',
                          style: TextStyle(
                            fontSize: 12,
                            color: CyberpunkTheme.neonPink.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Starfield particle painter for animated background.
class _StarfieldPainter extends CustomPainter {
  final double progress;
  final Random _rng = Random(42);

  _StarfieldPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (int i = 0; i < 80; i++) {
      final baseX = _rng.nextDouble() * size.width;
      final baseY = _rng.nextDouble() * size.height;
      final speed = 0.3 + _rng.nextDouble() * 0.7;
      final phase = _rng.nextDouble();

      final x = (baseX + progress * speed * 60) % size.width;
      final y = baseY;

      final brightness =
          (0.2 + 0.6 * ((sin((progress + phase) * 2 * pi) + 1) / 2));

      final isAccent = i % 7 == 0;
      paint.color = isAccent
          ? CyberpunkTheme.neonPink.withOpacity(brightness * 0.4)
          : CyberpunkTheme.neonCyan.withOpacity(brightness * 0.25);

      final radius = isAccent ? 1.8 : 1.0 + _rng.nextDouble() * 0.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
