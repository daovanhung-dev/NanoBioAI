import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/safety_contact.dart';
import '../../providers/sleep_safety_providers.dart';

class SleepSafetyContactsPage extends ConsumerWidget {
  const SleepSafetyContactsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sleepSafetyControllerProvider);
    final controller = ref.read(sleepSafetyControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Người liên hệ an toàn')),
      floatingActionButton: state.contacts.length >= 3
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _edit(context, controller, null),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Thêm người'),
            ),
      body: RefreshIndicator(
        onRefresh: controller.refreshContacts,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Bạn có thể thiết lập tối đa 3 người. Chỉ số điện thoại đã xác '
              'minh mới được dùng khi Nabi cần gửi cảnh báo hỗ trợ.',
            ),
            const SizedBox(height: 16),
            if (state.contacts.isEmpty)
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
                    '${_verificationText(contact.verificationStatus)}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'verify') {
                        await _verify(context, controller, contact);
                      } else if (value == 'edit') {
                        await _edit(context, controller, contact);
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
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Xóa'),
                      ),
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
    dynamic controller,
    SafetyContact? contact,
  ) async {
    final name = TextEditingController(text: contact?.name);
    final relation = TextEditingController(text: contact?.relationship);
    final phone = TextEditingController(text: contact?.phoneE164);
    var priority = contact?.priority ?? 1;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(
            contact == null
                ? 'Thêm người liên hệ'
                : 'Chỉnh sửa người liên hệ',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Tên'),
                ),
                TextField(
                  controller: relation,
                  decoration: const InputDecoration(labelText: 'Mối quan hệ'),
                ),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại (+84...)',
                  ),
                ),
                DropdownButtonFormField<int>(
                  initialValue: priority,
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
                    setState(() => priority = value ?? priority);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && context.mounted) {
      try {
        await controller.saveContact(
          id: contact?.id,
          name: name.text,
          relationship: relation.text,
          phoneE164: phone.text,
          priority: priority,
        );
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
        }
      }
    }

    name.dispose();
    relation.dispose();
    phone.dispose();
  }

  static Future<void> _verify(
    BuildContext context,
    dynamic controller,
    SafetyContact contact,
  ) async {
    try {
      await controller.requestVerification(contact.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
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
          ).showSnackBar(SnackBar(content: Text(error.toString())));
        }
      }
    }
    code.dispose();
  }
}
