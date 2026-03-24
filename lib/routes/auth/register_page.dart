import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// In-app registration page for creating a Pixelfed account.
class RegisterPage extends StatefulWidget {
  final String instanceUrl;

  const RegisterPage({Key? key, required this.instanceUrl}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _registrationComplete = false;

  // Availability checks
  bool? _usernameAvailable;
  bool? _emailAvailable;
  bool _checkingUsername = false;
  bool _checkingEmail = false;
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  String get _baseUrl {
    final url = widget.instanceUrl;
    if (url.startsWith('http')) return url;
    return 'https://$url';
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  /// Check username availability via Pixelfed API.
  Future<void> _checkUsername() async {
    final username = _usernameController.text.trim();
    if (username.length < 2) return;

    setState(() => _checkingUsername = true);
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/v1.1/auth/invite/admin/uc'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username}),
          )
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _checkingUsername = false;
          _usernameAvailable = response.statusCode == 200;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _checkingUsername = false;
          _usernameAvailable = null;
        });
      }
    }
  }

  /// Check email availability via Pixelfed API.
  Future<void> _checkEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) return;

    setState(() => _checkingEmail = true);
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/v1.1/auth/invite/admin/ec'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _checkingEmail = false;
          _emailAvailable = response.statusCode == 200;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _checkingEmail = false;
          _emailAvailable = null;
        });
      }
    }
  }

  /// Submit registration.
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final body = <String, dynamic>{
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'password_confirmation': _passwordController.text,
      };

      final inviteCode = _inviteCodeController.text.trim();
      if (inviteCode.isNotEmpty) {
        body['invite_code'] = inviteCode;
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/v1.1/auth/iar'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isLoading = false;
          _registrationComplete = true;
        });
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _isLoading = false;
          _errorMessage = data['message'] ??
              data['error'] ??
              'Registration failed. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Connection error. Please check your internet.';
        });
      }
    }
  }

  /// Password strength (0-4).
  int _passwordStrength(String password) {
    if (password.isEmpty) return 0;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    return strength;
  }

  Color _strengthColor(int strength) {
    switch (strength) {
      case 0:
        return CyberpunkTheme.textTertiary;
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orange;
      case 3:
        return CyberpunkTheme.neonYellow;
      case 4:
        return const Color(0xFF00E676);
      default:
        return CyberpunkTheme.textTertiary;
    }
  }

  String _strengthLabel(int strength) {
    switch (strength) {
      case 0:
        return '';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_registrationComplete) {
      return _buildConfirmationScreen();
    }

    final uri = Uri.tryParse(_baseUrl);
    final hostName = uri?.host ?? widget.instanceUrl;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // Ambient glow
            Positioned(
              top: -100,
              right: -60,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    CyberpunkTheme.neonCyan.withOpacity(0.08),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    CyberpunkTheme.neonPink.withOpacity(0.06),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // Back button
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),

                      const SizedBox(height: 16),

                      // Title
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            CyberpunkTheme.neonCyan,
                            CyberpunkTheme.neonPink
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'Create Account',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join $hostName',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Username
                      _buildInputField(
                        controller: _usernameController,
                        label: 'Username',
                        hint: 'Choose a username',
                        icon: Icons.alternate_email_rounded,
                        validator: (v) {
                          if (v == null || v.trim().length < 2)
                            return 'Min. 2 characters';
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                            return 'Letters, numbers, underscores only';
                          }
                          return null;
                        },
                        onEditingComplete: _checkUsername,
                        suffixWidget: _checkingUsername
                            ? _loadingIndicator()
                            : _availabilityIcon(_usernameAvailable),
                      ),

                      const SizedBox(height: 16),

                      // Email
                      _buildInputField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'your@email.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null ||
                              !v.contains('@') ||
                              !v.contains('.')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                        onEditingComplete: _checkEmail,
                        suffixWidget: _checkingEmail
                            ? _loadingIndicator()
                            : _availabilityIcon(_emailAvailable),
                      ),

                      const SizedBox(height: 16),

                      // Password
                      _buildInputField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Choose a strong password',
                        icon: Icons.lock_outline_rounded,
                        obscure: !_showPassword,
                        validator: (v) {
                          if (v == null || v.length < 8)
                            return 'Min. 8 characters';
                          return null;
                        },
                        suffixWidget: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: CyberpunkTheme.textTertiary,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),

                      // Password strength indicator
                      if (_passwordController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildStrengthIndicator(),
                      ],

                      const SizedBox(height: 16),

                      // Invite code (optional)
                      _buildInputField(
                        controller: _inviteCodeController,
                        label: 'Invite Code (optional)',
                        hint: 'Enter invite code if you have one',
                        icon: Icons.card_giftcard_rounded,
                      ),

                      // Error message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.redAccent.withOpacity(0.1),
                            border: Border.all(
                                color: Colors.redAccent.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.redAccent, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                      color: Colors.redAccent, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Register button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [
                                CyberpunkTheme.neonCyan,
                                Color(0xFF0077CC)
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CyberpunkTheme.neonCyan.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _isLoading ? null : _register,
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Create Account',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Terms notice
                      Center(
                        child: Text(
                          'By creating an account, you agree to the\nserver rules and terms of service.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onEditingComplete,
    Widget? suffixWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 0.5,
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            onEditingComplete: onEditingComplete,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 15,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Icon(icon,
                    color: CyberpunkTheme.neonCyan.withOpacity(0.6), size: 20),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: suffixWidget,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStrengthIndicator() {
    final strength = _passwordStrength(_passwordController.text);
    final color = _strengthColor(strength);
    final label = _strengthLabel(strength);

    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i < strength ? color : CyberpunkTheme.borderDark,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _loadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(12),
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: CyberpunkTheme.neonCyan),
      ),
    );
  }

  Widget? _availabilityIcon(bool? available) {
    if (available == null) return null;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Icon(
        available ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: available ? const Color(0xFF00E676) : Colors.redAccent,
        size: 20,
      ),
    );
  }

  Widget _buildConfirmationScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // Glow
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  CyberpunkTheme.neonCyan.withOpacity(0.1),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          CyberpunkTheme.neonCyan.withOpacity(0.2),
                          CyberpunkTheme.neonCyan.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: CyberpunkTheme.neonCyan.withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      color: CyberpunkTheme.neonCyan,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Check Your Email',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We sent a confirmation email to\n${_emailController.text.trim()}\n\nClick the link to activate your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: CyberpunkTheme.neonCyan.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(
                          color: CyberpunkTheme.neonCyan,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
