import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../session_controller.dart';
import 'activity_chat_screen.dart';

class PlazaScreen extends StatefulWidget {
  const PlazaScreen({
    super.key,
    required this.sessionController,
  });

  final SessionController sessionController;

  @override
  State<PlazaScreen> createState() => _PlazaScreenState();
}

class _PlazaScreenState extends State<PlazaScreen> {
  static const List<String> _categories = <String>[
    '全部',
    '桌游',
    '运动',
    '小酌',
    '旅行',
    '电影',
  ];

  List<ActivityItem> _activities = <ActivityItem>[];
  bool _loading = true;
  String? _error;
  int _selectedCategory = 0;

  int? get _userId => widget.sessionController.session?.userId;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<ActivityItem> items = await ApiService.instance.getActivities(
        userId: _userId,
      );
      if (!mounted) return;
      setState(() => _activities = items);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<ActivityItem> get _filteredActivities {
    if (_selectedCategory == 0) {
      return _activities;
    }
    final String keyword = _categories[_selectedCategory].toLowerCase();
    return _activities.where((ActivityItem item) {
      final String merged =
          '${item.name} ${item.description ?? ''}'.toLowerCase();
      return merged.contains(keyword);
    }).toList();
  }

  Future<void> _join(ActivityItem activity) async {
    final int? userId = _userId;
    if (userId == null) {
      _showMessage('请先登录后再加入活动');
      return;
    }
    if (activity.creatorId == userId) {
      _showMessage('这是你发起的活动，不需要重复加入');
      return;
    }
    try {
      await ApiService.instance.joinActivity(
        activityId: activity.id,
        userId: userId,
      );
      _showMessage('报名申请已提交，等团长通过后就能进群');
      await _loadActivities();
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  void _openChat(ActivityItem activity) {
    final int? userId = _userId;
    if (userId == null) {
      _showMessage('请先登录');
      return;
    }
    final bool canChat =
        activity.creatorId == userId || activity.joinStatus == 'approved';
    if (!canChat) {
      _showMessage('加入并通过审核后，才能进入活动群聊');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ActivityChatScreen(
          activity: activity,
          sessionController: widget.sessionController,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final List<ActivityItem> displayItems = _filteredActivities;
    final List<ActivityItem> leftColumn = <ActivityItem>[];
    final List<ActivityItem> rightColumn = <ActivityItem>[];
    for (int i = 0; i < displayItems.length; i++) {
      if (i.isEven) {
        leftColumn.add(displayItems[i]);
      } else {
        rightColumn.add(displayItems[i]);
      }
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFFFFF8F4), Color(0xFFF5F5FF), Color(0xFFF4FBFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadActivities,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 96),
          children: <Widget>[
            const _PlazaTopBanner(),
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (BuildContext context, int index) {
                  final bool selected = _selectedCategory == index;
                  return InkWell(
                    onTap: () => setState(() => _selectedCategory = index),
                    borderRadius: BorderRadius.circular(999),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? const LinearGradient(
                                colors: <Color>[
                                  Color(0xFFFFA36C),
                                  Color(0xFFFF7B8F),
                                ],
                              )
                            : null,
                        color: selected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : const Color(0xFFE8DCF4),
                        ),
                      ),
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          color: selected ? Colors.white : const Color(0xFF6B6075),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _PlazaStateCard(
                title: '广场加载失败',
                description: _error!,
                actionLabel: '重试',
                onTap: _loadActivities,
              )
            else if (displayItems.isEmpty)
              _PlazaStateCard(
                title: '这一栏还没人发车',
                description: '换个标签看看，或者你来当第一个发起人。',
                actionLabel: '刷新广场',
                onTap: _loadActivities,
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      children: leftColumn
                          .map(
                            (ActivityItem item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PlazaWaterfallCard(
                                activity: item,
                                compact: false,
                                isCreator: item.creatorId == _userId,
                                onJoin: () => _join(item),
                                onChat: () => _openChat(item),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: rightColumn
                          .map(
                            (ActivityItem item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PlazaWaterfallCard(
                                activity: item,
                                compact: true,
                                isCreator: item.creatorId == _userId,
                                onJoin: () => _join(item),
                                onChat: () => _openChat(item),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PlazaTopBanner extends StatelessWidget {
  const _PlazaTopBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFF9F6E), Color(0xFFFFC36A), Color(0xFFFF7D8D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33FF9F6E),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '广场灵感墙',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '这里更适合随手逛、找同频的人和临时起意的局，和首页的“快速报名”形成差异。',
            style: TextStyle(color: Color(0xFFFDF2F8), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _PlazaWaterfallCard extends StatelessWidget {
  const _PlazaWaterfallCard({
    required this.activity,
    required this.compact,
    required this.isCreator,
    required this.onJoin,
    required this.onChat,
  });

  final ActivityItem activity;
  final bool compact;
  final bool isCreator;
  final VoidCallback onJoin;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final String statusText = switch (activity.joinStatus) {
      'approved' => '已加入',
      'pending' => '审核中',
      'rejected' => '被拒绝',
      _ => isCreator ? '你发起的局' : '可报名',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: compact ? 118 : 154,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: compact
                    ? const <Color>[Color(0xFF6A5AE0), Color(0xFF8FD3F4)]
                    : const <Color>[Color(0xFFFFA36C), Color(0xFFFF7B8F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x26FFFFFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Text(
                    activity.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            activity.description?.trim().isNotEmpty == true
                ? activity.description!
                : '这场活动还缺一个会玩的人，也许就是你。',
            maxLines: compact ? 3 : 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6B6075),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _MiniTag(label: _formatDate(activity.activityDate)),
              _MiniTag(label: '¥${activity.contractAmount}'),
              _MiniTag(label: '已通过 ${activity.approvedCount}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton(
                  onPressed: isCreator || activity.joinStatus == 'approved'
                      ? null
                      : onJoin,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C5A),
                    minimumSize: const Size.fromHeight(42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isCreator
                        ? '我的活动'
                        : activity.joinStatus == 'approved'
                            ? '已加入'
                            : activity.joinStatus == 'pending'
                                ? '审核中'
                                : '上车',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onChat,
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF6A5AE0),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(String raw) {
    final DateTime? date = DateTime.tryParse(raw);
    if (date == null) return '时间待定';
    final String mm = date.month.toString().padLeft(2, '0');
    final String dd = date.day.toString().padLeft(2, '0');
    return '$mm/$dd';
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF5E5673),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlazaStateCard extends StatelessWidget {
  const _PlazaStateCard({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: <Widget>[
          const Icon(Icons.explore_off_rounded, size: 38, color: Color(0xFF7C6D8E)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onTap, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
