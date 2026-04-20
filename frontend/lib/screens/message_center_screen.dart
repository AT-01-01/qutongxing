import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../app_localization.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../session_controller.dart';
import 'activity_chat_screen.dart';

class MessageCenterScreen extends StatefulWidget {
  const MessageCenterScreen({
    super.key,
    required this.sessionController,
    required this.localization,
    this.onUnreadChanged,
  });

  final SessionController sessionController;
  final AppLocalization localization;
  final ValueChanged<int>? onUnreadChanged;

  @override
  State<MessageCenterScreen> createState() => _MessageCenterScreenState();
}

class _MessageCenterScreenState extends State<MessageCenterScreen> {
  bool _loading = true;
  List<_ConversationItem> _conversations = <_ConversationItem>[];
  Timer? _refreshTimer;
  bool _loadingConversations = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _refreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _loadConversations(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (_loadingConversations) return;
    _loadingConversations = true;
    final int? userId = widget.sessionController.session?.userId;
    if (userId == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      _loadingConversations = false;
      return;
    }
    if (!silent) {
      setState(() => _loading = true);
    }
    try {
      final List<ChatConversationSummary> summaries =
          await ApiService.instance.getChatConversations(userId: userId);
      final List<_ConversationItem> data = <_ConversationItem>[];
      int unreadCount = 0;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      for (final ChatConversationSummary summary in summaries) {
        final int? lastMessageId = summary.lastMessageId;
        final int lastReadId = prefs.getInt(
              'chat_last_read_${userId}_${summary.activityId}',
            ) ??
            0;
        final bool unread = lastMessageId != null &&
            summary.lastSenderId != null &&
            summary.lastSenderId != userId &&
            lastMessageId > lastReadId;
        if (unread) unreadCount += 1;
        final ActivityItem activity = ActivityItem(
          id: summary.activityId,
          name: summary.activityName,
          description: null,
          activityDate: '',
          contractAmount: 0,
          creatorName: '',
        );
        data.add(
          _ConversationItem(
            activity: activity,
            lastText: summary.lastMessageContent ?? '暂无消息',
            lastTime: summary.lastMessageTime ?? '',
            unread: unread,
          ),
        );
      }
      if (!mounted) return;
      setState(() => _conversations = data);
      widget.onUnreadChanged?.call(unreadCount);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
      _loadingConversations = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFFF8FAFC), Color(0xFFEEF2FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadConversations,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
                children: <Widget>[
                  Row(
                    children: const <Widget>[
                      _QuickMessageEntry(
                        icon: Icons.favorite_border,
                        label: '互动消息',
                      ),
                      _QuickMessageEntry(
                        icon: Icons.notifications_none,
                        label: '系统通知',
                      ),
                      _QuickMessageEntry(
                        icon: Icons.campaign_outlined,
                        label: '活动公告',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '消息列表',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  if (_conversations.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('暂无聊天会话')),
                      ),
                    )
                  else
                    ..._conversations.map((_ConversationItem conversation) {
                      return Card(
                        child: ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ActivityChatScreen(
                                activity: conversation.activity,
                                sessionController: widget.sessionController,
                              ),
                            ),
                          ).then((_) => _loadConversations()),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFDDD6FE),
                            child: Text(
                              conversation.activity.name.isEmpty
                                  ? '群'
                                  : conversation.activity.name.characters.first,
                              style: const TextStyle(
                                color: Color(0xFF5B21B6),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(
                            conversation.activity.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            conversation.lastText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                conversation.lastTime.length >= 16
                                    ? conversation.lastTime.substring(11, 16)
                                    : '',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (conversation.unread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _ConversationItem {
  _ConversationItem({
    required this.activity,
    required this.lastText,
    required this.lastTime,
    required this.unread,
  });

  final ActivityItem activity;
  final String lastText;
  final String lastTime;
  final bool unread;
}

class _QuickMessageEntry extends StatelessWidget {
  const _QuickMessageEntry({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: <Widget>[
              Icon(icon, color: const Color(0xFF6D5EF9)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
