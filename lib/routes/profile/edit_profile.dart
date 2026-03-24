import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/models/account.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:fedispace/widgets/skeleton_loading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

/// Cyberpunk-themed profile editing page
class EditProfilePage extends StatefulWidget {
  final ApiService apiService;

  const EditProfilePage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();

  Account? _account;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _newAvatarFile;
  File? _newHeaderFile;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    try {
      final account = await widget.apiService.getCurrentAccount();
      setState(() {
        _account = account;
        _displayNameController.text = account.display_name;
        _bioController.text = account.note;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      appLogger.error('Error loading account', error, stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(bool isAvatar) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: isAvatar ? 400 : 1500,
      maxHeight: isAvatar ? 400 : 500,
    );

    if (pickedFile != null) {
      setState(() {
        if (isAvatar) {
          _newAvatarFile = File(pickedFile.path);
        } else {
          _newHeaderFile = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      appLogger.debug('Saving profile');
      await widget.apiService.updateCredentials(
        displayName: _displayNameController.text,
        note: _bioController.text,
        avatar: _newAvatarFile,
        header: _newHeaderFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).profileUpdated)),
        );
        Navigator.pop(context, true);
      }
    } catch (error, stackTrace) {
      appLogger.error('Error saving profile', error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).error)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: CyberpunkTheme.backgroundBlack,
        appBar: AppBar(
          backgroundColor: CyberpunkTheme.backgroundBlack,
          title: Text(S.of(context).editProfile,
              style: GoogleFonts.inter(
                  color: CyberpunkTheme.textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
        ),
        body: const SingleChildScrollView(child: ProfileSkeleton()),
      );
    }

    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: CyberpunkTheme.backgroundBlack,
        title: Text(
          S.of(context).editProfile,
          style: GoogleFonts.inter(
            color: CyberpunkTheme.textWhite,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: InstagramLoadingIndicator(size: 20),
                  )
                : Text(
                    S.of(context).done,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: CyberpunkTheme.neonCyan,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: CyberpunkTheme.spacingL),
              // Avatar
              GestureDetector(
                onTap: () => _pickImage(true),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: CyberpunkTheme.neonCyan.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: CyberpunkTheme.neonCyan.withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: CyberpunkTheme.cardDark,
                          backgroundImage: _newAvatarFile != null
                              ? FileImage(_newAvatarFile!) as ImageProvider
                              : (_account?.avatar.isNotEmpty ?? false)
                                  ? CachedNetworkImageProvider(_account!.avatar)
                                  : null,
                          child: (_newAvatarFile == null &&
                                  (_account?.avatar.isEmpty ?? true))
                              ? const Icon(Icons.person,
                                  size: 50, color: CyberpunkTheme.textTertiary)
                              : null,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: CyberpunkTheme.neonCyan,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: CyberpunkTheme.backgroundBlack,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CyberpunkTheme.spacingS),
              Text(
                S.of(context).changeProfilePhoto,
                style: GoogleFonts.inter(
                  color: CyberpunkTheme.neonCyan,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: CyberpunkTheme.spacingXXL),
              const InstagramDivider(),
              _buildTextField(
                label: 'Name',
                controller: _displayNameController,
                maxLength: 30,
              ),
              const InstagramDivider(),
              _buildTextField(
                label: 'Username',
                value: _account?.username ?? '',
                enabled: false,
              ),
              const InstagramDivider(),
              _buildTextField(
                label: 'Bio',
                controller: _bioController,
                maxLength: 150,
                maxLines: 3,
              ),
              const InstagramDivider(),
              const SizedBox(height: CyberpunkTheme.spacingL),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: CyberpunkTheme.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Header Image',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CyberpunkTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: CyberpunkTheme.spacingM),
                    GestureDetector(
                      onTap: () => _pickImage(false),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(CyberpunkTheme.radiusS),
                          border: Border.all(color: CyberpunkTheme.borderDark),
                        ),
                        child: _newHeaderFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    CyberpunkTheme.radiusS),
                                child: Image.file(
                                  _newHeaderFile!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : (_account?.header.isNotEmpty ?? false)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        CyberpunkTheme.radiusS),
                                    child: CachedNetworkImage(
                                      imageUrl: _account!.header,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 40,
                                          color: CyberpunkTheme.textTertiary,
                                        ),
                                        const SizedBox(
                                            height: CyberpunkTheme.spacingS),
                                        Text(
                                          'Add Header Image',
                                          style: GoogleFonts.inter(
                                            color: CyberpunkTheme.textTertiary,
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
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    String? value,
    int maxLength = 100,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: CyberpunkTheme.spacingL,
          vertical: CyberpunkTheme.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: CyberpunkTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: CyberpunkTheme.spacingL),
          Expanded(
            child: TextFormField(
              controller: controller,
              initialValue: controller == null ? value : null,
              enabled: enabled,
              maxLength: maxLength,
              maxLines: maxLines,
              style: GoogleFonts.inter(
                  fontSize: 16, color: CyberpunkTheme.textWhite),
              decoration: InputDecoration(
                border: InputBorder.none,
                counterText: '',
                hintText: label,
                hintStyle: GoogleFonts.inter(
                  color: CyberpunkTheme.textTertiary,
                ),
                filled: false,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
