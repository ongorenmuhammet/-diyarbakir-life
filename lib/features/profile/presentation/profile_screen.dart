import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../core/safety/ugc_safety_widgets.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/notifications/notification_settings_screen.dart';
import 'edit_profile_screen.dart';
import 'user_listings_screen.dart';
import '../../admin/presentation/admin_requests_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isRegisterMode = false;
  bool _eulaAccepted = false;
  bool _obscurePassword = true;
  String? _selectedAvatarPath;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_isRegisterMode) {
        if (!_eulaAccepted) {
          setState(() {
            _errorMessage = 'Kayıt olmak için Kullanım Koşulları ve Topluluk Kurallarını (EULA) kabul etmelisiniz.';
          });
          return;
        }
        final avatar = _selectedAvatarPath ?? '';
        
        final success = await ref.read(authProvider.notifier).register(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              avatarUrl: avatar,
            );

        if (!success) {
          setState(() {
            _errorMessage = 'Bu e-posta adresi zaten kullanımda veya geçersiz!';
          });
        } else {
          setState(() {
            _errorMessage = null;
          });
        }
      } else {
        final success = await ref.read(authProvider.notifier).login(
              _emailController.text,
              _passwordController.text,
            );
        if (!success) {
          setState(() {
            _errorMessage = 'Geçersiz e-posta veya şifre!';
          });
        } else {
          setState(() {
            _errorMessage = null;
          });
        }
      }
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 360,
        maxHeight: 360,
        imageQuality: 35,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Str = base64Encode(bytes);
        final mimeType = image.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
        setState(() {
          _selectedAvatarPath = 'data:$mimeType;base64,$base64Str';
        });
      }
    } catch (_) {}
  }

  void _showChangePasswordDialog(BuildContext context, bool isLoggedIn) {
    final dialogFormKey = GlobalKey<FormState>();
    final emailDialogController = TextEditingController();
    final oldPasswordDialogController = TextEditingController();
    final newPasswordDialogController = TextEditingController();
    final confirmPasswordDialogController = TextEditingController();
    String? dialogError;

    if (isLoggedIn) {
      emailDialogController.text = ref.read(authProvider).email ?? '';
    }

    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.vpn_key_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Şifre Değiştir'),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: dialogFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dialogError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Text(
                            dialogError!,
                            style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      if (!isLoggedIn) ...[
                        TextFormField(
                          controller: emailDialogController,
                          decoration: InputDecoration(
                            labelText: 'Hesap E-postası',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => value == null || value.trim().isEmpty ? 'E-posta boş bırakılamaz' : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: oldPasswordDialogController,
                        decoration: InputDecoration(
                          labelText: 'Mevcut Şifre',
                          prefixIcon: const Icon(Icons.shield_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        obscureText: obscureOld,
                        validator: (value) => value == null || value.isEmpty ? 'Mevcut şifre boş bırakılamaz' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPasswordDialogController,
                        decoration: InputDecoration(
                          labelText: 'Yeni Şifre',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        obscureText: obscureNew,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Yeni şifre boş bırakılamaz';
                          if (value.length < 6) return 'Yeni şifre en az 6 karakter olmalıdır';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordDialogController,
                        decoration: InputDecoration(
                          labelText: 'Yeni Şifre (Tekrar)',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        obscureText: obscureConfirm,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Şifre onayı boş bırakılamaz';
                          if (value != newPasswordDialogController.text) return 'Yeni şifreler eşleşmiyor';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        icon: const Icon(Icons.mail_outline, size: 18),
                        label: const Text('Şifremi Hatırlamıyorum (E-posta Gönder)'),
                        onPressed: () async {
                          final email = emailDialogController.text.trim();
                          if (email.isEmpty) {
                            setDialogState(() {
                              dialogError = 'E-posta adresi bulunamadı!';
                            });
                            return;
                          }
                          setDialogState(() {
                            dialogError = null;
                          });
                          final success = await ref
                              .read(authProvider.notifier)
                              .sendOfficialResetEmail(email);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? '📬 Şifre sıfırlama bağlantısı e-posta adresinize gönderildi. Lütfen spam kutunuzu da kontrol edin.'
                                      : 'ℹ️ Şifre sıfırlama talebi alındı. E-posta kutunuzu kontrol ediniz.',
                                ),
                                backgroundColor: Colors.blue.shade700,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (dialogFormKey.currentState!.validate()) {
                      final success = await ref.read(authProvider.notifier).changePassword(
                            email: emailDialogController.text.trim(),
                            oldPassword: oldPasswordDialogController.text,
                            newPassword: newPasswordDialogController.text,
                          );
                      if (success) {
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Şifreniz başarıyla değiştirildi.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        setDialogState(() {
                          dialogError = 'E-posta veya mevcut şifre hatalı!';
                        });
                      }
                    }
                  },
                  child: const Text('Şifreyi Güncelle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final dialogFormKey = GlobalKey<FormState>();
    final emailDialogController = TextEditingController(text: _emailController.text.trim());
    final newPasswordDialogController = TextEditingController();
    final confirmPasswordDialogController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    int resetMode = 0; // 0: E-posta Sıfırlama Bağlantısı (Resmi), 1: Hızlı Şifre Güncelleme (Uygulama İçi)
    String? dialogError;
    bool isSending = false;

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.lock_reset, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Şifremi Unuttum'),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: dialogFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('📧 E-posta Linki', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              selected: resetMode == 0,
                              onSelected: (val) {
                                if (val) setDialogState(() => resetMode = 0);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('⚡ Hızlı Sıfırla', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              selected: resetMode == 1,
                              onSelected: (val) {
                                if (val) setDialogState(() => resetMode = 1);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        resetMode == 0
                            ? 'Kayıtlı e-posta adresinizi girin. E-posta kutunuza resmi şifre sıfırlama bağlantısı gönderilecektir.'
                            : 'Kayıtlı e-posta adresinizi ve yeni şifrenizi girerek uygulama içerisinden anında sıfırlayın.',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      if (dialogError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Text(
                            dialogError!,
                            style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      TextFormField(
                        controller: emailDialogController,
                        decoration: InputDecoration(
                          labelText: 'Kayıtlı E-posta Adresi',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value == null || value.trim().isEmpty ? 'E-posta boş bırakılamaz' : null,
                      ),
                      if (resetMode == 1) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: newPasswordDialogController,
                          decoration: InputDecoration(
                            labelText: 'Yeni Şifre',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          obscureText: obscureNew,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Yeni şifre boş bırakılamaz';
                            if (value.length < 6) return 'Yeni şifre en az 6 karakter olmalıdır';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: confirmPasswordDialogController,
                          decoration: InputDecoration(
                            labelText: 'Yeni Şifre (Tekrar)',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          obscureText: obscureConfirm,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Şifre onayı boş bırakılamaz';
                            if (value != newPasswordDialogController.text) return 'Yeni şifreler eşleşmiyor';
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          if (dialogFormKey.currentState!.validate()) {
                            setDialogState(() {
                              isSending = true;
                              dialogError = null;
                            });

                            if (resetMode == 0) {
                              final success = await ref
                                  .read(authProvider.notifier)
                                  .sendOfficialResetEmail(emailDialogController.text.trim());
                              setDialogState(() => isSending = false);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? '📬 Şifre sıfırlama bağlantısı e-posta adresinize gönderildi. Lütfen gelen kutunuzu kontrol edin.'
                                          : 'ℹ️ Şifre sıfırlama talebi alındı. E-posta kutunuzu kontrol ediniz.',
                                    ),
                                    backgroundColor: Colors.blue.shade700,
                                  ),
                                );
                              }
                            } else {
                              final success = await ref.read(authProvider.notifier).resetPasswordWithEmail(
                                    email: emailDialogController.text.trim(),
                                    newPassword: newPasswordDialogController.text,
                                  );
                              setDialogState(() => isSending = false);
                              if (success) {
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Şifreniz başarıyla sıfırlandı! Yeni şifrenizle giriş yapabilirsiniz.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
                                setDialogState(() {
                                  dialogError = 'Bu e-posta adresiyle kayıtlı bir hesap bulunamadı!';
                                });
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(resetMode == 0 ? 'Bağlantı Gönder' : 'Şifremi Güncelle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text('Profil & Ayarlar'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            authState.isAuthenticated
                ? _buildProfileDashboard(context, authState)
                : _buildAuthForm(context, theme, isDark),
            const SizedBox(height: 24),
            _buildNotificationSettingsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthForm(BuildContext context, ThemeData theme, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            _isRegisterMode ? 'Yeni Kullanıcı Kaydı' : 'Giriş Yap',
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _isRegisterMode
                ? 'Bilgilerinizi girerek hızlıca yeni bir kullanıcı hesabı oluşturun.'
                : 'Hesabınıza erişmek veya yeni içerikleri takip etmek için e-posta ve şifrenizle giriş yapın.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (_isRegisterMode) ...[
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: (_selectedAvatarPath != null && _selectedAvatarPath!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(46),
                              child: AppImage(
                                path: _selectedAvatarPath!,
                                height: 92,
                                width: 92,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(Icons.person, size: 48, color: theme.colorScheme.primary),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _pickAvatar,
                icon: const Icon(Icons.photo_library, size: 18),
                label: Text((_selectedAvatarPath != null && _selectedAvatarPath!.isNotEmpty)
                    ? 'Fotoğrafı Değiştir'
                    : 'Galeriden Fotoğraf Seç'),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Ad Soyad',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Ad soyad boş bırakılamaz';
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],

          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'E-posta',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'E-posta boş bırakılamaz';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Şifre',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Şifre boş bırakılamaz';
              if (value.length < 6) return 'Şifre en az 6 karakter olmalıdır';
              return null;
            },
          ),
          if (_isRegisterMode) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _eulaAccepted,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) {
                      setState(() {
                        _eulaAccepted = val ?? false;
                        if (_eulaAccepted && _errorMessage != null && _errorMessage!.contains('EULA')) {
                          _errorMessage = null;
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => showEulaDialog(context),
                      child: Text.rich(
                        TextSpan(
                          text: 'Kullanıcı Sözleşmesi ve Topluluk Kurallarını (EULA)',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          children: const [
                            TextSpan(
                              text: ' okudum ve kabul ediyorum.',
                              style: TextStyle(
                                color: Colors.grey,
                                decoration: TextDecoration.none,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(_isRegisterMode ? 'Profil Oluştur ve Giriş Yap' : 'Giriş Yap',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          // Sign in with Apple (Resmi Apple Bileşeni)
          SignInWithAppleButton(
            onPressed: () async {
              final success = await ref.read(authProvider.notifier).loginWithApple();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Apple hesabınızla başarıyla giriş yapıldı!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            text: 'Apple ile Giriş Yap',
            height: 54,
            style: isDark ? SignInWithAppleButtonStyle.white : SignInWithAppleButtonStyle.black,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: () async {
                final success = await ref.read(authProvider.notifier).loginWithGoogle();
                if (success) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Google hesabınızla başarıyla giriş yapıldı!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.g_mobiledata, size: 32, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Google ile Giriş Yap',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: () => showEulaDialog(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    text: 'Giriş yaparak veya kayıt olarak ',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                    children: [
                      TextSpan(
                        text: 'Kullanım Koşulları ve EULA Sözleşmesini',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                      const TextSpan(
                        text: ' kabul etmiş olursunuz.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_isRegisterMode) ...[
            Center(
              child: TextButton(
                onPressed: () => _showForgotPasswordDialog(context),
                child: Text(
                  'Şifremi Unuttum / Sıfırla',
                  style: TextStyle(
                    color: theme.colorScheme.primary.withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _isRegisterMode = !_isRegisterMode;
                  _errorMessage = null;
                });
              },
              child: Text(
                _isRegisterMode
                    ? 'Zaten bir hesabınız var mı? Giriş Yap'
                    : 'Hesabınız yok mu? Yeni Hesap Oluştur',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.gavel_outlined, size: 16),
              onPressed: () => showEulaDialog(context),
              label: const Text(
                'Kullanıcı Sözleşmesi & Güvenlik Politikası (EULA)',
                style: TextStyle(fontSize: 12, decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDashboard(BuildContext context, AuthState auth) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: (auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(48),
                        child: AppImage(
                          path: auth.avatarUrl!,
                          height: 96,
                          width: 96,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(Icons.person, size: 54, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                auth.name!,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (auth.isAdmin) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Sistem Yöneticisi (Admin)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(auth.email!, style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildDashboardOption(
          context,
          icon: Icons.manage_accounts_outlined,
          title: 'Profil Bilgilerini Düzenle',
          subtitle: 'İsim, e-posta ve resminizi güncelleyin.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
            );
          },
        ),
        _buildDashboardOption(
          context,
          icon: Icons.assignment_outlined,
          title: 'İlanlarım & Gönderilerim',
          subtitle: 'Paylaştığınız tüm ilanları ve onay durumlarını inceleyin.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const UserListingsScreen()),
            );
          },
        ),
        _buildDashboardOption(
          context,
          icon: Icons.notifications_active_outlined,
          title: 'Bildirim Ayarları',
          subtitle: 'Ezan, hava durumu ve haber bildirimlerini yönetin.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
            );
          },
        ),
        if (auth.isAdmin) ...[
          _buildDashboardOption(
            context,
            icon: Icons.dashboard_customize_outlined,
            title: 'Yönetim Paneli (Admin)',
            subtitle: 'Haber, İşletme, İlan ve Giriş İstatistiklerini yönetin.',
            iconColor: Colors.purple.shade700,
            onTap: () {
              context.push('/admin');
            },
          ),
          _buildDashboardOption(
            context,
            icon: Icons.mark_email_unread_outlined,
            title: 'İstekler / İlan Onayları',
            subtitle: 'Onay bekleyen içerik ve talepleri yönetin.',
            iconColor: Colors.orange.shade800,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AdminRequestsScreen()),
              );
            },
          ),
          _buildDashboardOption(
            context,
            icon: Icons.shield_outlined,
            title: 'Yetkilendirme Durumu',
            subtitle: 'Tüm alanlar düzenlenebilir ve yönetilebilir.',
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
        ],
        _buildDashboardOption(
          context,
          icon: Icons.vpn_key_outlined,
          title: 'Şifre Değiştir',
          subtitle: 'Güvenliğiniz için şifrenizi güncelleyin.',
          onTap: () => _showChangePasswordDialog(context, true),
        ),
        _buildDashboardOption(
          context,
          icon: Icons.gavel_outlined,
          title: 'Kullanıcı Sözleşmesi & EULA',
          subtitle: 'Topluluk kuralları ve güvenlik politikalarımız.',
          onTap: () => showEulaDialog(context),
        ),
        _buildDashboardOption(
          context,
          icon: Icons.logout,
          title: 'Oturumu Kapat',
          subtitle: 'Düzenleme yetkilerini sonlandırır.',
          textColor: Colors.red,
          iconColor: Colors.red,
          onTap: () {
            ref.read(authProvider.notifier).logout();
          },
        ),
        _buildDashboardOption(
          context,
          icon: Icons.delete_forever,
          title: 'Hesabımı Kalıcı Olarak Sil',
          subtitle: 'Hesabınızı ve tüm kişisel verilerinizi kalıcı olarak siler.',
          textColor: Colors.red.shade700,
          iconColor: Colors.red.shade700,
          onTap: () => _confirmDeleteAccount(context),
        ),
      ],
    );
  }

  Widget _buildNotificationSettingsCard(BuildContext context) {
    final notifySettings = ref.watch(notificationSettingsProvider);
    final notifyNotifier = ref.read(notificationSettingsProvider.notifier);
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Bildirim Ayarları ve Tasarım Testleri',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Bildirim tercihlerinizi yönetin ve özel tasarımları tek tıkla cihazınızda test edin.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Divider(),

            // 1. Weather Notification
            _buildNotificationTile(
              context,
              icon: const CircleAvatar(
                backgroundColor: Colors.orangeAccent,
                radius: 18,
                child: Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 20),
              ),
              title: 'Hava Durumu Bildirimleri',
              subtitle: 'Her sabah 08:00\'de günlük hava durumu özeti gönderir.',
              value: notifySettings.weatherNotify,
              onChanged: (val) => notifyNotifier.toggleWeather(val),
              buttonColor: Colors.orange,
            ),

            // 2. Currency Notification
            _buildNotificationTile(
              context,
              icon: const CircleAvatar(
                backgroundColor: Colors.green,
                radius: 18,
                child: Icon(Icons.attach_money, color: Colors.white, size: 20),
              ),
              title: 'Döviz & Finans Bildirimleri',
              subtitle: 'Günde 1 kez öğlen 12:00\'de güncel döviz kurları bildirimi gönderir.',
              value: notifySettings.currencyNotify,
              onChanged: (val) => notifyNotifier.toggleCurrency(val),
              buttonColor: Colors.green,
            ),

            // 3. Prayer Times Notification
            _buildNotificationTile(
              context,
              icon: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                radius: 18,
                child: Icon(Icons.access_time_outlined, color: Colors.white, size: 20),
              ),
              title: 'Ezan Vakitleri Bildirimleri',
              subtitle: 'Her namaz vaktinden 45 dakika önce hatırlatma bildirimi gönderir.',
              value: notifySettings.prayerNotify,
              onChanged: (val) => notifyNotifier.togglePrayer(val),
              buttonColor: Colors.blue,
            ),

            // 4. News Notification
            _buildNotificationTile(
              context,
              icon: const CircleAvatar(
                backgroundColor: Colors.redAccent,
                radius: 18,
                child: Icon(Icons.newspaper_outlined, color: Colors.white, size: 20),
              ),
              title: 'Haber Bildirimleri',
              subtitle: 'Sisteme yeni bir haber eklendiğinde anında son dakika bildirimi gönderir.',
              value: notifySettings.newsNotify,
              onChanged: (val) => notifyNotifier.toggleNews(val),
              buttonColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildNotificationTile(
    BuildContext context, {
    required Widget icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color buttonColor, // Keeping buttonColor parameter as it might be useful later, or we can just ignore it for now.
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        const Divider(height: 16),
      ],
    );
  }


  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hesabımı Sil'),
          ],
        ),
        content: const Text(
          'Hesabınızı silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz. Profiliniz, ilanlarınız ve tüm verileriniz sunucularımızdan kalıcı olarak silinecektir.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref.read(authProvider.notifier).deleteAccount();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Hesabınız ve verileriniz başarıyla silindi.' : 'Hesap silinirken bir hata oluştu.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Evet, Hesabımı Sil'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
