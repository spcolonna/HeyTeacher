import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo - en producción vendrían de Firebase
    final notifications = [
      {
        'title': 'New Job Match',
        'body': 'A new job posting matches your profile',
        'time': DateTime.now().subtract(const Duration(hours: 2)),
        'read': false,
        'icon': Icons.work,
        'color': Colors.blue,
      },
      {
        'title': 'Application Update',
        'body': 'Your application was reviewed',
        'time': DateTime.now().subtract(const Duration(days: 1)),
        'read': false,
        'icon': Icons.visibility,
        'color': Colors.green,
      },
      {
        'title': 'New Material Available',
        'body': 'Check out the latest teaching resources',
        'time': DateTime.now().subtract(const Duration(days: 2)),
        'read': true,
        'icon': Icons.folder,
        'color': Colors.orange,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('All notifications marked as read')),
              );
            },
            child: const Text('Mark all read',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off,
                      size: 64, color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _NotificationTile(
                  title: notif['title'] as String,
                  body: notif['body'] as String,
                  time: notif['time'] as DateTime,
                  isRead: notif['read'] as bool,
                  icon: notif['icon'] as IconData,
                  color: notif['color'] as Color,
                );
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String body;
  final DateTime time;
  final bool isRead;
  final IconData icon;
  final Color color;

  const _NotificationTile({
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    required this.icon,
    required this.color,
  });

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(body),
          const SizedBox(height: 4),
          Text(
            _getTimeAgo(time),
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: !isRead
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification tapped')),
        );
      },
    );
  }
}
