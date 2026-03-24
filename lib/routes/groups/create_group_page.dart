import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/groups_api.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';

/// Create Group page with name, description, category, and privacy options.
class CreateGroupPage extends StatefulWidget {
  final ApiService apiService;

  const CreateGroupPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  late final GroupsApi _groupsApi;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  String _privacy = 'public';
  bool _isCreating = false;

  static const _privacyOptions = ['public', 'private'];

  @override
  void initState() {
    super.initState();
    _groupsApi = GroupsApi(apiService: widget.apiService);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name is required')),
      );
      return;
    }

    setState(() => _isCreating = true);
    final result = await _groupsApi.createGroup(
      name: name,
      description: _descriptionController.text.trim(),
      category: _categoryController.text.trim(),
      privacy: _privacy,
    );
    setState(() => _isCreating = false);

    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create group')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Create Group'),
        backgroundColor: CyberpunkTheme.backgroundBlack,
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroup,
            child: _isCreating
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: CyberpunkTheme.neonCyan))
                : const Text('Create', style: TextStyle(color: CyberpunkTheme.neonCyan, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Name
          const Text('Group Name', style: TextStyle(color: CyberpunkTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Enter group name'),
            maxLength: 100,
          ),
          const SizedBox(height: 20),

          // Description
          const Text('Description', style: TextStyle(color: CyberpunkTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(hintText: 'What is this group about?'),
            maxLines: 4,
            maxLength: 500,
          ),
          const SizedBox(height: 20),

          // Category
          const Text('Category', style: TextStyle(color: CyberpunkTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(hintText: 'e.g., Technology, Art, Music'),
          ),
          const SizedBox(height: 20),

          // Privacy
          const Text('Privacy', style: TextStyle(color: CyberpunkTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: CyberpunkTheme.glassWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CyberpunkTheme.glassBorder),
            ),
            child: Column(
              children: _privacyOptions.map((option) {
                final isSelected = _privacy == option;
                return RadioListTile<String>(
                  value: option,
                  groupValue: _privacy,
                  onChanged: (v) => setState(() => _privacy = v!),
                  title: Text(
                    option == 'public' ? 'Public' : 'Private',
                    style: TextStyle(
                      color: isSelected ? CyberpunkTheme.neonCyan : CyberpunkTheme.textWhite,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    option == 'public'
                        ? 'Anyone can find and join this group'
                        : 'Members must be approved to join',
                    style: const TextStyle(color: CyberpunkTheme.textTertiary, fontSize: 12),
                  ),
                  activeColor: CyberpunkTheme.neonCyan,
                  dense: true,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
