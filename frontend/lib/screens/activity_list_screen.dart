import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_localization.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../session_controller.dart';
import 'activity_chat_screen.dart';
import 'message_center_screen.dart';
import 'payment_mock_screen.dart';
import 'plaza_screen.dart';
import 'profile_screen.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({
    super.key,
    required this.sessionController,
    required this.localization,
  });

  final SessionController sessionController;
  final AppLocalization localization;

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ActivityItem> _activities = <ActivityItem>[];
  bool _loading = true;
  String? _loadError;
  String _sortBy = '';
  String _sortOrder = '';
  int _bottomTab = 0;
  Timer? _autoRefreshTimer;
  int _unreadCount = 0;
  bool _refreshingUnread = false;

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _refreshUnreadCount();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      if (_bottomTab == 0) {
        _silentRefreshActivities();
        _refreshUnreadCount();
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final int? userId = widget.sessionController.session?.userId;
      final List<ActivityItem> list = await ApiService.instance.getActivities(
        userId: userId,
        keyword: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        sortBy: _sortBy.isEmpty ? null : _sortBy,
        sortOrder: _sortOrder.isEmpty ? null : _sortOrder,
      );
      if (!mounted) return;
      setState(() => _activities = list);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _activities = <ActivityItem>[];
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _silentRefreshActivities() async {
    try {
      final int? userId = widget.sessionController.session?.userId;
      final List<ActivityItem> list = await ApiService.instance.getActivities(
        userId: userId,
        keyword: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        sortBy: _sortBy.isEmpty ? null : _sortBy,
        sortOrder: _sortOrder.isEmpty ? null : _sortOrder,
      );
      if (!mounted) return;
      setState(() => _activities = list);
    } catch (_) {}
  }

  Future<void> _refreshUnreadCount() async {
    if (_refreshingUnread) return;
    final int? userId = widget.sessionController.session?.userId;
    if (userId == null) {
      if (!mounted) return;
      setState(() => _unreadCount = 0);
      return;
    }
    _refreshingUnread = true;
    try {
      final List<ChatConversationSummary> conversations =
          await ApiService.instance.getChatConversations(userId: userId);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int unread = conversations.fold<int>(0, (int sum, ChatConversationSummary item) {
        final int? lastId = item.lastMessageId;
        if (lastId == null || lastId <= 0) {
          return sum;
        }
        final int lastRead =
            prefs.getInt('chat_last_read_${userId}_${item.activityId}') ?? 0;
        final bool isUnread =
            item.lastSenderId != null &&
            item.lastSenderId != userId &&
            lastId > lastRead;
        return isUnread ? sum + 1 : sum;
      });
      if (!mounted) return;
      setState(() => _unreadCount = unread);
    } catch (_) {
      // 保持静默，避免轮询影响主流程。
    } finally {
      _refreshingUnread = false;
    }
  }

  Future<void> _joinActivity(ActivityItem activity) async {
    final int? userId = widget.sessionController.session?.userId;
    if (userId == null) {
      _showMessage('请先登录');
      return;
    }
    final bool isSelfCreated = activity.creatorId == userId ||
        activity.creatorName == widget.sessionController.session?.username;
    if (isSelfCreated) {
      _showBlockingAlert(
        title: '操作受限',
        content: widget.localization.tr('selfJoinBlocked'),
      );
      return;
    }
    final bool confirmed = await _confirmJoinFlow(activity);
    if (!confirmed) {
      _showMessage(widget.localization.tr('payCancelled'));
      return;
    }
    try {
      await ApiService.instance.joinActivity(
        activityId: activity.id,
        userId: userId,
      );
      _showMessage(widget.localization.tr('paySuccess'));
      await _loadActivities();
    } on ApiException catch (error) {
      _showBlockingAlert(title: '提示', content: error.message);
    }
  }

  Future<void> _requestQuit(ActivityItem activity) async {
    final int? userId = widget.sessionController.session?.userId;
    if (userId == null) {
      _showMessage('请先登录');
      return;
    }
    try {
      final QuitPolicyPreview preview = await ApiService.instance.getQuitPreview(
        activityId: activity.id,
        userId: userId,
      );
      if (!mounted) return;
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('退出规则确认'),
            content: Text(
              '${preview.message}\n\n'
              '预计返还: ¥${preview.refundAmount}\n'
              '扣除金额: ¥${preview.penaltyAmount}\n\n'
              '确认后将进入支付确认页。',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确认并继续'),
              ),
            ],
          );
        },
      );
      if (confirmed != true) {
        return;
      }
      final bool? paid = await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(
          builder: (_) => PaymentMockScreen(
            activity: activity,
            localization: widget.localization,
          ),
        ),
      );
      if (paid != true) {
        _showMessage('已取消退出申请支付确认');
        return;
      }
      await ApiService.instance.requestQuitWithConfirm(
        activityId: activity.id,
        userId: userId,
        confirmed: true,
      );
      _showMessage('已提交退出申请，等待团长审核');
      await _loadActivities();
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _cancelApplication(ActivityItem activity) async {
    final int? userId = widget.sessionController.session?.userId;
    if (userId == null) {
      _showMessage('请先登录');
      return;
    }
    try {
      await ApiService.instance.quitActivity(
        activityId: activity.id,
        userId: userId,
      );
      _showMessage('已取消报名申请');
      await _loadActivities();
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<bool> _confirmJoinFlow(ActivityItem activity) async {
    final AppLocalization i18n = widget.localization;
    final String ruleText = _buildContractRuleText(activity);
    final bool? agreed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(i18n.tr('confirmJoinTitle')),
          content: Text(
            '${i18n.tr('confirmJoinContent')}\n\n'
            '$ruleText',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(i18n.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(i18n.tr('goToPay')),
            ),
          ],
        );
      },
    );
    if (agreed != true) {
      return false;
    }
    final bool? paid = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => PaymentMockScreen(
          activity: activity,
          localization: i18n,
        ),
      ),
    );
    return paid == true;
  }

  String _buildContractRuleText(ActivityItem activity) {
    final String part1 =
        '1. 活动开始~前${activity.refundBeforeMinutes}分钟：返还${(activity.refundBeforeMinutesRate * 100).toStringAsFixed(0)}%';
    final String part2 =
        '2. 前${activity.refundBeforeMinutes}分钟~前${activity.refundBeforeHours}小时：返还${(activity.refundBeforeHoursRate * 100).toStringAsFixed(0)}%';
    final String part3 =
        '3. 前${activity.refundBeforeHours}小时以前：返还${(activity.refundBeforeEarlyRate * 100).toStringAsFixed(0)}%';
    return '契约规则：\n$part1\n$part2\n$part3';
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: const Text('默认排序'),
                onTap: () {
                  setState(() {
                    _sortBy = '';
                    _sortOrder = '';
                  });
                  Navigator.pop(context);
                  _loadActivities();
                },
              ),
              ListTile(
                title: const Text('契约金从高到低'),
                onTap: () {
                  setState(() {
                    _sortBy = 'contractAmount';
                    _sortOrder = 'desc';
                  });
                  Navigator.pop(context);
                  _loadActivities();
                },
              ),
              ListTile(
                title: const Text('活动时间从早到晚'),
                onTap: () {
                  setState(() {
                    _sortBy = 'activityDate';
                    _sortOrder = 'asc';
                  });
                  Navigator.pop(context);
                  _loadActivities();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPublishPanel() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return GestureDetector(
          onVerticalDragUpdate: (DragUpdateDetails details) {
            if (details.delta.dy > 8) {
              Navigator.pop(context);
            }
          },
          child: Material(
            color: Colors.black38,
            child: Column(
              children: <Widget>[
                const Spacer(),
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 76),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '请选择发布类型',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      _PublishTile(
                        icon: Icons.event_note_outlined,
                        title: '活动',
                        subtitle: '发起拼团、约活动',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            this.context,
                            '/create',
                          ).then((_) => _loadActivities());
                        },
                      ),
                      _PublishTile(
                        icon: Icons.workspace_premium_outlined,
                        title: '悬赏',
                        subtitle: '任务悬赏、跑腿求助',
                        onTap: () {
                          Navigator.pop(context);
                          _showMessage('悬赏发布功能开发中');
                        },
                      ),
                      _PublishTile(
                        icon: Icons.group_add_outlined,
                        title: '找搭子',
                        subtitle: '找人组队、找同伴',
                        onTap: () {
                          Navigator.pop(context);
                          _showMessage('找搭子功能开发中');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onBottomTap(int index) {
    if (index == 2) {
      _openPublishPanel();
      return;
    }
    if (_bottomTab == index) return;
    setState(() => _bottomTab = index);
    if (index == 3 || index == 0 || index == 1) {
      _refreshUnreadCount();
    }
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    int? badgeCount,
  }) {
    final bool selected = _bottomTab == index;
    final int badge = badgeCount ?? 0;
    return Expanded(
      child: InkWell(
        onTap: () => _onBottomTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 24,
              height: 24,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Align(
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 20,
                      color: selected
                          ? const Color(0xFF6D5EF9)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(minWidth: 14),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          badge > 99 ? '99+' : badge.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF6D5EF9)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(ActivityItem activity) {
    final String? status = activity.joinStatus;
    if (status == 'approved') {
      return ElevatedButton(
        onPressed: () => _requestQuit(activity),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444),
        ),
        child: Text(widget.localization.tr('applyQuit')),
      );
    }
    if (status == 'pending') {
      return OutlinedButton(
        onPressed: () => _cancelApplication(activity),
        child: Text(widget.localization.tr('cancelApplication')),
      );
    }
    if (status == 'rejected') {
      return OutlinedButton(
        onPressed: () => _cancelApplication(activity),
        child: Text(widget.localization.tr('deleteRecord')),
      );
    }
    return ElevatedButton(
      onPressed: () => _joinActivity(activity),
      child: Text(widget.localization.tr('joinNow')),
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

  void _showBlockingAlert({required String title, required String content}) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('我知道了'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return ListView(
        children: <Widget>[
          const SizedBox(height: 90),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 42,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '活动加载失败',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: _loadActivities,
                        icon: const Icon(Icons.refresh),
                        label: const Text('重新加载'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_activities.isEmpty) {
      return ListView(
        children: const <Widget>[
          SizedBox(height: 120),
          Center(child: Text('暂无活动')),
        ],
      );
    }

    return ListView.builder(
      itemCount: _activities.length,
      itemBuilder: (BuildContext context, int index) {
        final ActivityItem item = _activities[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(item.description ?? '无描述'),
                const SizedBox(height: 10),
                Text(
                  '创建人: ${item.creatorName}  ·  契约金: ¥${item.contractAmount}  ·  已报名: ${item.approvedCount}人',
                ),
                const SizedBox(height: 6),
                Text(
                  '活动时间: ${item.activityDate}',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(child: _buildAction(item)),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ActivityChatScreen(
                            activity: item,
                            sessionController: widget.sessionController,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.forum_outlined),
                      label: const Text('交流'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _bottomTab == 0
              ? widget.localization.tr('activities')
              : (_bottomTab == 1
                    ? '广场'
                    : (_bottomTab == 3 ? '消息' : widget.localization.tr('profile'))),
        ),
        actions: <Widget>[
          if (_bottomTab == 0 || _bottomTab == 1) ...<Widget>[
            IconButton(onPressed: _showSortSheet, icon: const Icon(Icons.sort)),
            IconButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/manage',
              ).then((_) => _loadActivities()),
              icon: const Icon(Icons.manage_accounts),
            ),
          ],
        ],
      ),
      body: _bottomTab == 0
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Color(0xFFF4F6FF),
                    Color(0xFFECEFFF),
                    Color(0xFFF8FAFC),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFF6D5EF9), Color(0xFF8B80FF)],
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x336D5EF9),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '今日灵感广场',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text('快速组局、立即报名、高效匹配同城搭子', style: TextStyle(color: Color(0xFFEDE9FE))),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 94,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
                      scrollDirection: Axis.horizontal,
                      children: const <Widget>[
                        _HomeIdeaCard(title: '今日热门', sub: '同城桌游组局'),
                        _HomeIdeaCard(title: '附近新局', sub: '3 公里内可达'),
                        _HomeIdeaCard(title: '轻悬赏', sub: '跑腿与任务大厅'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: '搜索活动名称或描述',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onSubmitted: (_) => _loadActivities(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _loadActivities,
                          child: const Text('查询'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildListContent()),
                ],
              ),
            )
          : _bottomTab == 1
              ? const PlazaScreen()
              : _bottomTab == 3
              ? MessageCenterScreen(
                  sessionController: widget.sessionController,
                  localization: widget.localization,
                  onUnreadChanged: (int value) {
                    if (!mounted) return;
                    setState(() => _unreadCount = value);
                  },
                )
              : ProfileScreen(
                  sessionController: widget.sessionController,
                  localization: widget.localization,
                  embedded: true,
                ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: <Widget>[
                _buildNavItem(icon: Icons.home_rounded, label: '首页', index: 0),
                _buildNavItem(icon: Icons.explore_outlined, label: '广场', index: 1),
                Expanded(
                  child: InkWell(
                    onTap: () => _onBottomTap(2),
                    child: Center(
                      child: Transform.translate(
                        offset: const Offset(0, -7),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6D5EF9),
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Color(0x336D5EF9),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildNavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '消息',
                  index: 3,
                  badgeCount: _unreadCount,
                ),
                _buildNavItem(icon: Icons.person_rounded, label: '我的', index: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PublishTile extends StatelessWidget {
  const _PublishTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF6D5EF9)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _HomeIdeaCard extends StatelessWidget {
  const _HomeIdeaCard({required this.title, required this.sub});

  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
