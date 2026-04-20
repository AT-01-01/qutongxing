import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../session_controller.dart';

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
      final List<ActivityItem> created = await ApiService.instance
          .getActivitiesByCreator(userId);
      final List<ActivityItem> joined = await ApiService.instance
          .getActivitiesByParticipant(userId);
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
      _showMessage('删除成功');
      await _loadData();
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _showParticipants(ActivityItem activity) async {
    try {
      // 这里需要同时展示“待审核报名”和“退出申请”记录。
      // 后端的 /participants 接口已经按该规则返回，前端只需要按字段判断按钮类型。
      final List<ParticipantItem> participants = await ApiService.instance
          .getParticipants(activity.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('报名管理 - ${activity.name}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: participants.isEmpty
                    ? const Center(child: Text('暂无待处理记录'))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: participants.length,
                        itemBuilder: (BuildContext context, int index) {
                          final ParticipantItem p = participants[index];
                          final bool isQuitRequest = p.quitRequested;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    p.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '状态: ${p.status}${p.quitRequested ? ' (申请退出)' : ''}',
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            if (isQuitRequest) {
                                              await ApiService.instance
                                                  .approveQuitRequest(
                                                    activityId: activity.id,
                                                    participantId: p.id,
                                                  );
                                            } else {
                                              await ApiService.instance
                                                  .approveParticipant(
                                                    activityId: activity.id,
                                                    participantId: p.id,
                                                  );
                                            }
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                            }
                                            await _showParticipants(activity);
                                            await _loadData();
                                          },
                                          child: const Text('同意'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            if (isQuitRequest) {
                                              await ApiService.instance
                                                  .rejectQuitRequest(
                                                    activityId: activity.id,
                                                    participantId: p.id,
                                                  );
                                            } else {
                                              await ApiService.instance
                                                  .rejectParticipant(
                                                    activityId: activity.id,
                                                    participantId: p.id,
                                                  );
                                            }
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                            }
                                            await _showParticipants(activity);
                                            await _loadData();
                                          },
                                          child: const Text('拒绝'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          );
        },
      );
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final List<ActivityItem> currentList = _tabIndex == 0 ? _created : _joined;
    return Scaffold(
      appBar: AppBar(title: const Text('活动管理')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFFF4F6FF),
              Color(0xFFEDEFFF),
              Color(0xFFF8FAFC),
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
                  padding: const EdgeInsets.all(12),
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0xFF6D5EF9), Color(0xFF8D7BFF)],
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '我的活动空间',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '统一处理创建、审批、参与记录',
                            style: TextStyle(color: Color(0xFFEDE9FE)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        ChoiceChip(
                          label: Text('我创建的活动 (${_created.length})'),
                          selected: _tabIndex == 0,
                          onSelected: (_) => setState(() => _tabIndex = 0),
                        ),
                        ChoiceChip(
                          label: Text('我参加的活动 (${_joined.length})'),
                          selected: _tabIndex == 1,
                          onSelected: (_) => setState(() => _tabIndex = 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (currentList.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: Text('暂无数据')),
                        ),
                      )
                    else
                      ...currentList.map((ActivityItem item) {
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _tabIndex == 0
                                    ? '待处理: ${item.pendingCount + item.quitRequestedCount}  ·  已报名: ${item.approvedCount}'
                                    : '创建人: ${item.creatorName}',
                              ),
                            ),
                            trailing: _tabIndex == 0
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      IconButton(
                                        onPressed: () =>
                                            _showParticipants(item),
                                        icon: const Icon(
                                          Icons.people_alt_outlined,
                                        ),
                                        tooltip: '报名管理',
                                      ),
                                      IconButton(
                                        onPressed: () => _deleteActivity(item),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        tooltip: '删除活动',
                                      ),
                                    ],
                                  )
                                : const Icon(Icons.chevron_right),
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
