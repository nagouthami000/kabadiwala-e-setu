import 'package:flutter/material.dart';
import 'app_repository.dart';
import 'glass_ui.dart';
import 'localization_service.dart';
import 'supabase_service.dart';

class AuthScreen extends StatefulWidget {
  final Function(String role, String name) onLoginSuccess;
  final IndicLanguage initialLanguage;
  final Function(IndicLanguage lang)? onLanguageChanged;

  const AuthScreen({
    super.key,
    required this.onLoginSuccess,
    this.initialLanguage = IndicLanguage.english,
    this.onLanguageChanged,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _supabase = SupabaseService();
  final _repository = AppRepository();

  bool isSignUp = false;
  String selectedRole = 'collector'; // 'collector' or 'recycler'
  bool isLoading = false;
  String? errorMessage;
  
  final phoneCtrl = TextEditingController(text: '9876543210');
  final nameCtrl = TextEditingController(text: 'Ramesh Kabadi');
  final pinCtrl = TextEditingController(text: '1234');
  final mpcbCtrl = TextEditingController(text: 'MPCB/EW/2026/0491');
  
  late IndicLanguage currentLang;
  bool obscurePin = true;

  @override
  void initState() {
    super.initState();
    currentLang = widget.initialLanguage;
  }

  @override
  void dispose() {
    phoneCtrl.dispose();
    nameCtrl.dispose();
    pinCtrl.dispose();
    mpcbCtrl.dispose();
    super.dispose();
  }

  String _formatEmail(String input) {
    final trimmed = input.trim();
    if (trimmed.contains('@')) return trimmed;
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    return 'k_${digits.isEmpty ? 'user' : digits}@ekabadi.com';
  }

  String _formatPassword(String pin) {
    final clean = pin.trim();
    if (clean.length >= 6) return clean;
    return '$clean#Kbd26';
  }

  Future<void> _submitAuth() async {
    final identifier = phoneCtrl.text.trim();
    final pin = pinCtrl.text.trim();

    if (identifier.isEmpty) {
      setState(() => errorMessage = 'Please enter your mobile number or email');
      return;
    }
    if (pin.isEmpty || pin.length < 4) {
      setState(() => errorMessage = 'PIN / Passcode must be at least 4 digits');
      return;
    }
    if (isSignUp && nameCtrl.text.trim().isEmpty) {
      setState(() => errorMessage = 'Please enter your name');
      return;
    }
    if (isSignUp && selectedRole == 'recycler' && mpcbCtrl.text.trim().isEmpty) {
      setState(() => errorMessage = 'Please enter your MPCB License Number');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final email = _formatEmail(identifier);
    final password = _formatPassword(pin);

    try {
      if (isSignUp) {
        final displayName = nameCtrl.text.trim();
        final res = await _supabase.signUp(
          email: email,
          password: password,
          data: {
            'role': selectedRole,
            'name': displayName,
            'phone': identifier,
            'mpcb': selectedRole == 'recycler' ? mpcbCtrl.text.trim() : '',
          },
        );

        if (!mounted) return;
        if (res['success'] == true) {
          final data = res['data'] as Map<String, dynamic>?;
          final token = data?['access_token']?.toString() ?? 'session_${DateTime.now().millisecondsSinceEpoch}';
          await _repository.saveSession(token: token, role: selectedRole, name: displayName);
          widget.onLoginSuccess(selectedRole, displayName);
        } else {
          final err = res['error']?.toString() ?? 'Sign up failed';
          setState(() => errorMessage = 'Supabase: $err');
        }
      } else {
        // Sign In
        final res = await _supabase.signIn(email: email, password: password);
        if (!mounted) return;
        if (res['success'] == true) {
          final data = res['data'] as Map<String, dynamic>?;
          final user = data?['user'] as Map<String, dynamic>?;
          final meta = user?['user_metadata'] as Map<String, dynamic>?;
          final token = data?['access_token']?.toString() ?? 'session_${DateTime.now().millisecondsSinceEpoch}';

          final resolvedRole = meta?['role']?.toString() ?? selectedRole;
          final resolvedName = meta?['name']?.toString() ?? 
              (resolvedRole == 'collector' ? 'Ramesh (Collector)' : 'EcoRecycle Corp');

          await _repository.saveSession(token: token, role: resolvedRole, name: resolvedName);
          widget.onLoginSuccess(resolvedRole, resolvedName);
        } else {
          final err = res['error']?.toString() ?? 'Invalid login credentials';
          if (err.toLowerCase().contains('invalid') || err.toLowerCase().contains('failed')) {
            setState(() => errorMessage = 'Account not found for this mobile number. Please tap "Create Account" above to register.');
          } else if (err.contains('Email not confirmed')) {
            setState(() => errorMessage = 'Supabase Notice: Email confirmation required. Disable "Confirm email" in Supabase Dashboard -> Auth to allow instant login.');
          } else {
            setState(() => errorMessage = 'Supabase Auth: $err');
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => errorMessage = 'Network connection error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0C241B);
    const emeraldSurface = Color(0xFF163E2E);
    const cardBorder = Color(0x554DF2C6);
    const limeAccent = Color(0xFFC6F24D);
    const mintGlow = Color(0xFF4DF2C6);

    return Scaffold(
      backgroundColor: VibrantColors.inkDark,
      body: EWasteAnimatedBackground(
        child: SafeArea(
          child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Language Selector Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: emeraldSurface.withAlpha(200),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: cardBorder),
                            ),
                            child: PopupMenuButton<IndicLanguage>(
                              tooltip: 'Select Language',
                              initialValue: currentLang,
                              onSelected: (l) {
                                setState(() => currentLang = l);
                                widget.onLanguageChanged?.call(l);
                              },
                              color: emeraldSurface,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.language_rounded, color: limeAccent, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    currentLang.nativeLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                                ],
                              ),
                              itemBuilder: (_) => IndicLanguage.values.map((l) {
                                return PopupMenuItem(
                                  value: l,
                                  child: Text(
                                    '${l.nativeLabel} (${l.englishLabel})',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Futuristic Branding Hero
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [limeAccent, mintGlow],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: limeAccent.withAlpha(70),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.recycling_rounded,
                            size: 42,
                            color: Color(0xFF081510),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        LocalizationService.text(currentLang, 'app_name', fallback: 'E-KABADI SETU'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        LocalizationService.text(
                          currentLang,
                          'tagline',
                          fallback: 'Sovereign AI E-Waste Bridge & Mission LiFE ESG',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withAlpha(180),
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Glassmorphism Card Container
                      GlassContainer(
                        padding: const EdgeInsets.all(22),
                        borderRadius: 24,
                        blur: 20,
                        tintColor: const Color(0xFF0F3626),
                        tintAlpha: 140,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Persona Segment Selector
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: bgDark.withAlpha(160),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cardBorder.withAlpha(80)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildRoleChip(
                                      roleId: 'collector',
                                      label: 'Kabadiwala',
                                      subtitle: 'Collector',
                                      icon: Icons.electric_rickshaw_rounded,
                                      accentColor: limeAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: _buildRoleChip(
                                      roleId: 'recycler',
                                      label: 'Recycler',
                                      subtitle: 'MPCB Authorized',
                                      icon: Icons.factory_rounded,
                                      accentColor: mintGlow,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Tab Switcher: Sign In vs Sign Up
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => isSignUp = false),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: !isSignUp ? limeAccent : Colors.transparent,
                                            width: 2.5,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Sign In',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: !isSignUp ? Colors.white : Colors.white38,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => isSignUp = true),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: isSignUp ? limeAccent : Colors.transparent,
                                            width: 2.5,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Create Account',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isSignUp ? Colors.white : Colors.white38,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Dynamic Input Fields
                            if (isSignUp) ...[
                              _buildInputField(
                                controller: nameCtrl,
                                label: selectedRole == 'collector' ? 'Full Name' : 'Authorized Enterprise Name',
                                icon: Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 12),
                            ],

                            _buildInputField(
                              controller: phoneCtrl,
                              label: 'Mobile Number (+91)',
                              icon: Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                            ),

                            if (selectedRole == 'recycler') ...[
                              const SizedBox(height: 12),
                              _buildInputField(
                                controller: mpcbCtrl,
                                label: 'MPCB License / Consent No.',
                                icon: Icons.verified_user_outlined,
                              ),
                            ],

                            const SizedBox(height: 12),
                            _buildInputField(
                              controller: pinCtrl,
                              label: 'Security PIN / Passcode',
                              icon: Icons.lock_outline_rounded,
                              obscureText: obscurePin,
                              keyboardType: TextInputType.number,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePin ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                                onPressed: () => setState(() => obscurePin = !obscurePin),
                              ),
                            ),

                            if (errorMessage != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade900.withAlpha(90),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.redAccent.withAlpha(150)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        errorMessage!,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 22),

                            // Primary Login Action Button
                            InkWell(
                              onTap: isLoading ? null : _submitAuth,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isLoading 
                                        ? [Colors.grey.shade700, Colors.grey.shade800]
                                        : [VibrantColors.neonLime, VibrantColors.mintCyan],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: isLoading ? [] : [
                                    BoxShadow(
                                      color: limeAccent.withAlpha(80),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isLoading) ...[
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    Text(
                                      isLoading 
                                          ? 'Authenticating...' 
                                          : (isSignUp ? 'Create & Launch' : 'Enter Dashboard'),
                                      style: TextStyle(
                                        color: isLoading ? Colors.white : const Color(0xFF081510),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    if (!isLoading) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Color(0xFF081510),
                                        size: 18,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),


                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildRoleChip({
    required String roleId,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = selectedRole == roleId;
    return InkWell(
      onTap: () => setState(() => selectedRole = roleId),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withAlpha(35) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? accentColor : Colors.white54,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? accentColor : Colors.white38,
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
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFFC6F24D), size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF081510).withAlpha(180),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x334DF2C6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC6F24D), width: 1.5),
        ),
      ),
    );
  }
}
