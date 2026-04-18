import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/admin_service.dart';

class MessageListScreen extends ConsumerWidget {
  const MessageListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(adminMessagesProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Inbox', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: messagesAsync.when(
        data: (messages) {
          if (messages.isEmpty) return const Center(child: Text('No messages found'));
          return ListView.separated(
            itemCount: messages.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final msg = messages[index];
              final bool isRead = msg['is_read'] == true;
              return ListTile(
                tileColor: isRead ? null : AppTheme.primary.withValues(alpha: 0.05),
                title: Text(
                  msg['name'] ?? 'Guest',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg['email'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(msg['message'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text(
                      msg['created_at'] != null ? DateFormat.yMMMd().format(DateTime.parse(msg['created_at'])) : '',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(isRead ? Icons.mark_email_read : Icons.mark_email_unread, color: isRead ? Colors.grey : AppTheme.primary),
                  onPressed: () async {
                    await AdminService.markMessageRead(msg['id'], !isRead);
                    ref.invalidate(adminMessagesProvider);
                  },
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Message from ${msg['name']}'),
                      content: SingleChildScrollView(child: Text(msg['message'] ?? '')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
