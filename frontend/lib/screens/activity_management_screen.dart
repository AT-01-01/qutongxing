import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../session_controller.dart';
import 'activity_chat_screen.dart';

class ActivityManagementScreen extends StatefulWidget {
  const ActivityManagementScreen({
    super.key,
    required this.sessionController,
  });

  final SessionController sessionController;

  @override
  State<ActivityManagementScreen> createState() =>
      _ActivityManagementScreenState();
}

class _ActivityManagementScreenState extends State<ActivityManagementScreen> {
  List<ActivityItem> _created = <ActivityItem>[];
  List<ActivityItem> _joined = <ActivityItem>[];
  bool _loading = true;
  int _tabIndex = 0;

  int get _todoCount => _created.fold<int>(
        0,
        (int sum, ActivityItem item) =>
            sum + item.pendingCount + item.quitRequestedCount,
      );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final int? userId = widget.sessionController.session?.userId;
    if (userId == null) {
      _showMessage('请先登录');
      return;
    }
    setState(() => _loading = true);
    try {
      final List<ActivityItem> created =
          await ApiService.instance.getActivitiesByCreator(userId);
      final List<ActivityItem> joined =
          await ApiService.instance.getActivitiesByParticipant(userId);
      if (!mounted) return;
      setState(() {
        _created = created;
        _joined = joined;
      });
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteActivity(ActivityItem activity) async {
    final int? userId = widget.sessionController.session?.userId;
    if (userId == null) return;
    try {
      await ApiService.instance.deleteActivity(
        activityId: activity.id,
        userId: userId,
      );
      _showMessage('活动已删除');
      await _loadData();
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _showParticipants(ActivityItem activity) async {
    try {
      final List<ParticipantItem> participants =
          await ApiService.instance.getParticipants(activity.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (BuildContext context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    activity.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '把报名申请、退局申请一次处理完。',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 12),
                  if (participants.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(child: Text('当前没有待处理记录')),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: participants.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (BuildContext context, int index) {
                          final ParticipantItem item = participants[index];
                          final bool isQuitRequest = item.quitRequested;
                          return _ParticipantActionCard(
                            participant: item,
                            onApprove: () async {
                              if (isQuitRequest) {
                                await ApiService.instance.approveQuitRequest(
                                  activityId: activity.id,
                                  participantId: item.id,
                                );
                              } else {
                                await ApiService.instance.approveParticipant(
                                  activityId: activity.id,
                                  participantId: item.id,
                                );
                              }
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              await _showParticipants(activity);
                              await _loadData();
                            },
                            onReject: () async {
                              if (isQuitRequest) {
                                await ApiService.instance.rejectQuitRequest(
                                  activityId: activity.id,
                                  participantId: item.id,
                                );
                              } else {
                                await ApiService.instance.rejectParticipant(
                                  activityId: activity.id,
                                  participantId: item.id,
                                );
                              }
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              await _showParticipants(activity);
                              await _loadData();
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  void _openChat(ActivityItem activity) {
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
    final List<ActivityItem> currentList = _tabIndex == 0 ? _created : _joined;

    return Scaffold(
      appBar: AppBar(title: const Text('活动管理台')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFFFFF9F5),
              Color(0xFFF5F3FF),
              Color(0xFFF6FCFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                  children: <Widget>[
                    _ManageHeroCard(
                      createdCount: _created.length,
                      joinedCount: _joined.length,
                      todoCount: _todoCount,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _SegmentButton(
                            selected: _tabIndex == 0,
                            title: '我发起的活动',
                            subtitle: '${_created.length} 场',
                            onTap: () => setState(() => _tabIndex = 0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SegmentButton(
                            selected: _tabIndex == 1,
                            title: '我参与的活动',
                            subtitle: '${_joined.length} 场',
                            onTap: () => setState(() => _tabIndex = 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (currentList.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('这里还没有活动记录')),
                        ),
                      )
                    else
                      ...currentList.map((ActivityItem item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _tabIndex == 0
                              ? _CreatedActivityCard(
                                  activity: item,
                                  onManage: () => _showParticipants(item),
                                  onDelete: () => _deleteActivity(item),
                                  onChat: () => _openChat(item),
                                )
                              : _JoinedActivityCard(
                                  activity: item,
                                  onChat: item.joinStatus == 'approved'
                                      ? () => _openChat(item)
                                      : null,
                                ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ManageHeroCard extends StatelessWidget {
  const _ManageHeroCard({
    required this.createdCount,
    required this.joinedCount,
    required this.todoCount,
  });

  final int createdCount;
  final int joinedCount;
  final int todoCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF6E61FF),
            Color(0xFF8A7CFF),
            Color(0xFF5BD0FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '活动管理台',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '团长在这里处理审核，参与者在这里追踪自己的状态。',
            style: TextStyle(color: Color(0xFFEDE9FE), height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(child: _ManageMetric(label: '发起', value: '$createdCount')),
              const SizedBox(width: 10),
              Expanded(child: _ManageMetric(label: '参与', value: '$joinedCount')),
              const SizedBox(width: 10),
              Expanded(child: _ManageMetric(label: '待办', value: '$todoCount')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManageMetric extends StatelessWidget {
  const _ManageMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFEDE9FE),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1F1632) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF1F1632) : const Color(0xFFE6E2F5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF241B35),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: selected ? const Color(0xFFD9D6FF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatedActivityCard extends StatelessWidget {
  const _CreatedActivityCard({
    required this.activity,
    required this.onManage,
    required this.onDelete,
    required this.onChat,
  });

  final ActivityItem activity;
  final VoidCallback onManage;
  final VoidCallback onDelete;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          Text(
            activity.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _CountChip(label: '待审核', value: activity.pendingCount),
              _CountChip(label: '退局申请', value: activity.quitRequestedCount),
              _CountChip(label: '已通过', value: activity.approvedCount),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: onManage,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('处理申请'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onChat,
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text('进入群聊'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JoinedActivityCard extends StatelessWidget {
  const _JoinedActivityCard({
    required this.activity,
    required this.onChat,
  });

  final ActivityItem activity;
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    final String statusText = switch (activity.joinStatus) {
      'approved' => '已通过，随时可以进群聊',
      'pending' => '审核中，等待团长处理',
      'rejected' => '已被拒绝，可返回首页换一场',
      _ => '状态同步中',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          Text(
            activity.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _StatusPill(label: '发起人 ${activity.creatorName}'),
              _StatusPill(label: '契约金 ¥${activity.contractAmount}'),
              _StatusPill(label: '状态 ${activity.joinStatus ?? 'unknown'}'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(onChat == null ? '群聊暂不可用' : '进入活动群聊'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: Color(0xFF5B4B8A),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF9A4E21),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ParticipantActionCard extends StatelessWidget {
  const _ParticipantActionCard({
    required this.participant,
    required this.onApprove,
    required this.onReject,
  });

  final ParticipantItem participant;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  @override
  Widget build(BuildContext context) {
    final bool isQuitRequest = participant.quitRequested;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E8F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            participant.username,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            isQuitRequest ? '申请退出活动' : '申请加入活动',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton(
                  onPressed: () => onApprove(),
                  child: Text(isQuitRequest ? '同意退出' : '通过报名'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onReject(),
                  child: Text(isQuitRequest ? '拒绝退出' : '拒绝报名'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
