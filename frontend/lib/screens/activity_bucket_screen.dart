import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../session_controller.dart';

enum ActivityBucketType { created, joined }

class ActivityBucketScreen extends StatefulWidget {
  const ActivityBucketScreen({
    super.key,
    required this.sessionController,
    required this.bucketType,
  });

  final SessionController sessionController;
  final ActivityBucketType bucketType;

  @override
  State<ActivityBucketScreen> createState() => _ActivityBucketScreenState();
}

class _ActivityBucketScreenState extends State<ActivityBucketScreen> {
  bool _loading = true;
  List<ActivityItem> _all = <ActivityItem>[];
  int _tab = 0; // 0 进行中，1 已完成

  bool _isDone(ActivityItem item) {
    final DateTime? date = DateTime.tryParse(item.activityDate);
    if (date == null) return false;
    return DateTime.now().isAfter(date);
  }

  Future<void> _load() async {
    final int? userId = widget.sessionController.session?.userId;
    if (userId == null) {
      return;
    }
    setState(() => _loading = true);
    try {
      final List<ActivityItem> data = widget.bucketType == ActivityBucketType.created
          ? await ApiService.instance.getActivitiesByCreator(userId)
          : await ApiService.instance.getActivitiesByParticipant(userId);
      if (!mounted) return;
      setState(() => _all = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final bool created = widget.bucketType == ActivityBucketType.created;
    final String title = created ? '我创建的活动' : '我参与的活动';
    final List<ActivityItem> list = _all.where((ActivityItem item) {
      final bool done = _isDone(item);
      return _tab == 0 ? !done : done;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: <Widget>[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: <Widget>[
              ChoiceChip(
                label: const Text('未完成'),
                selected: _tab == 0,
                onSelected: (_) => setState(() => _tab = 0),
              ),
              ChoiceChip(
                label: const Text('已完成'),
                selected: _tab == 1,
                onSelected: (_) => setState(() => _tab = 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? const Center(child: Text('暂无数据'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (BuildContext context, int index) {
                            final ActivityItem item = list[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                title: Text(item.name),
                                subtitle: Text(
                                  '活动时间: ${item.activityDate}\n'
                                  '创建人: ${item.creatorName} · 参与积分: ${item.contractAmount}',
                                ),
                                isThreeLine: true,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/manage',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
