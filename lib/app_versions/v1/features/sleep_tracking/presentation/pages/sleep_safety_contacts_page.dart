import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/safety_contact.dart';
import '../../providers/sleep_safety_controller.dart';
import '../../providers/sleep_safety_providers.dart';

class SleepSafetyContactsPage extends ConsumerWidget {
  const SleepSafetyContactsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sleepSafetyControllerProvider);
    final controller = ref.read(sleepSafetyControllerProvider.notifier);

    return MedicalPageScaffold(
      appBar: AppBar(title: const Text('Người liên hệ an toàn')),
      floatingActionButton: !state.contactsLoaded || state.contacts.length >= 3
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _edit(context, controller, null, state.contacts),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Thêm người'),
            ),
      body: RefreshIndicator(
        onRefresh: controller.refreshContacts,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Bạn có thể thiết lập tối đa 3 người. Có thể bật gọi thoại cho '
              'số chưa xác minh; xác minh chỉ cần để gửi SMS.',
            ),
            const SizedBox(height: 16),
            if (!state.contactsLoaded)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Expanded(child: Text('Đang tải người liên hệ an toàn…')),
                    ],
                  ),
                ),
              )
            else if (state.contacts.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Chưa có người liên hệ an toàn. Hãy thêm ít nhất một '
                    'người mà bạn tin tưởng.',
                  ),
                ),
              ),
            for (final contact in state.contacts)
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${contact.priority}')),
                  title: Text(contact.name),
                  subtitle: Text(
                    '${contact.relationship} • ${contact.phoneE164}\n'
                    '${_verificationText(contact.verificationStatus)}'
                    '${!contact.isVerified && contact.allowUnverifiedVoiceAlert ? ' • Đã bật gọi thoại' : ''}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'verify') {
                        await _verify(context, controller, contact);
                      } else if (value == 'edit') {
                        await _edit(
                          context,
                          controller,
                          contact,
                          state.contacts,
                        );
                      } else if (value == 'delete') {
                        await controller.deleteContact(contact.id);
                      }
                    },
                    itemBuilder: (_) => [
                      if (!contact.isVerified)
                        const PopupMenuItem(
                          value: 'verify',
                          child: Text('Xác minh'),
                        ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Chỉnh sửa'),
                      ),
                      const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  static String _verificationText(SafetyContactVerificationStatus value) =>
      switch (value) {
        SafetyContactVerificationStatus.verified => 'Đã xác minh',
        SafetyContactVerificationStatus.pending => 'Chờ xác minh',
        SafetyContactVerificationStatus.failed => 'Xác minh chưa thành công',
        SafetyContactVerificationStatus.revoked => 'Đã thu hồi xác minh',
      };

  static Future<void> _edit(
    BuildContext context,
    SleepSafetyController controller,
    SafetyContact? contact,
    List<SafetyContact> contacts,
  ) async {
    final draft = await showDialog<_SafetyContactDraft>(
      context: context,
      builder: (_) => _SafetyContactEditorDialog(
        contact: contact,
        initialPriority: contact?.priority ?? _firstAvailablePriority(contacts),
      ),
    );

    if (draft == null || !context.mounted) return;

    try {
      await controller.saveContact(
        id: contact?.id,
        name: draft.name,
        relationship: draft.relationship,
        phoneE164: draft.phoneE164,
        priority: draft.priority,
        allowPhoneFallback: draft.allowPhoneFallback,
        allowUnverifiedVoiceAlert: draft.allowUnverifiedVoiceAlert,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu người liên hệ an toàn.')),
      );
    }
  }

  static Future<void> _verify(
    BuildContext context,
    SleepSafetyController controller,
    SafetyContact contact,
  ) async {
    try {
      await controller.requestVerification(contact.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
      return;
    }

    if (!context.mounted) return;
    final code = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nhập mã xác minh'),
        content: TextField(
          controller: code,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Mã 6 số'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await controller.confirmVerification(contact.id, code.text);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
        }
      }
    }
    code.dispose();
  }

  static int _firstAvailablePriority(List<SafetyContact> contacts) {
    final used = contacts.map((contact) => contact.priority).toSet();
    return [
      1,
      2,
      3,
    ].firstWhere((priority) => !used.contains(priority), orElse: () => 1);
  }

  static String _friendlyError(Object error) {
    final message = error.toString();
    return message
        .replaceFirst(RegExp(r'^FormatException:\s*'), '')
        .replaceFirst(RegExp(r'^Bad state:\s*'), '');
  }
}

class _SafetyContactDraft {
  const _SafetyContactDraft({
    required this.name,
    required this.relationship,
    required this.phoneE164,
    required this.priority,
    required this.allowPhoneFallback,
    required this.allowUnverifiedVoiceAlert,
  });

  final String name;
  final String relationship;
  final String phoneE164;
  final int priority;
  final bool allowPhoneFallback;
  final bool allowUnverifiedVoiceAlert;
}

class _SafetyContactEditorDialog extends StatefulWidget {
  const _SafetyContactEditorDialog({
    required this.contact,
    required this.initialPriority,
  });

  final SafetyContact? contact;
  final int initialPriority;

  @override
  State<_SafetyContactEditorDialog> createState() =>
      _SafetyContactEditorDialogState();
}

class _SafetyContactEditorDialogState
    extends State<_SafetyContactEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _relationshipController;
  late final TextEditingController _phoneController;
  late int _priority;
  late bool _allowPhoneFallback;
  late bool _allowUnverifiedVoiceAlert;

  @override
  void initState() {
    super.initState();
    final contact = widget.contact;
    _nameController = TextEditingController(text: contact?.name);
    _relationshipController = TextEditingController(
      text: contact?.relationship,
    );
    _phoneController = TextEditingController(text: contact?.phoneE164);
    _priority = widget.initialPriority;
    _allowPhoneFallback = contact?.allowPhoneFallback ?? true;
    _allowUnverifiedVoiceAlert = contact?.allowUnverifiedVoiceAlert ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _SafetyContactDraft(
        name: _nameController.text,
        relationship: _relationshipController.text,
        phoneE164: _phoneController.text,
        priority: _priority,
        allowPhoneFallback: _allowPhoneFallback,
        allowUnverifiedVoiceAlert: _allowUnverifiedVoiceAlert,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.contact == null ? 'Thêm người liên hệ' : 'Chỉnh sửa người liên hệ',
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Tên'),
          ),
          TextField(
            controller: _relationshipController,
            decoration: const InputDecoration(labelText: 'Mối quan hệ'),
          ),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Số điện thoại (+84...)',
            ),
          ),
          DropdownButtonFormField<int>(
            initialValue: _priority,
            decoration: const InputDecoration(labelText: 'Ưu tiên'),
            items: [1, 2, 3]
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text('Ưu tiên $value'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _priority = value);
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Cho phép gọi thoại tự động khi chưa xác minh'),
            subtitle: const Text(
              'Mặc định tắt. Chỉ dùng cho cảnh báo tự động khi số chưa xác minh; không gửi SMS.',
            ),
            value: _allowUnverifiedVoiceAlert,
            onChanged: (value) =>
                setState(() => _allowUnverifiedVoiceAlert = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Cho phép gọi trực tiếp đến số này'),
            subtitle: const Text(
              'Dùng khi bạn chọn “Tôi cần hỗ trợ”. Android có thể gọi trực tiếp sau khi cấp quyền; iPhone yêu cầu xác nhận.',
            ),
            value: _allowPhoneFallback,
            onChanged: (value) => setState(() => _allowPhoneFallback = value),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Hủy'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Lưu')),
    ],
  );
}
