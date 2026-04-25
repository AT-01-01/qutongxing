import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_localization.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../session_controller.dart';
import '../widgets/avatar_badge.dart';
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
  static const List<String> _typeOptions = <String>[
    '全部',
    '桌游',
    '运动',
    '小酌',
    '旅行',
    '电影',
  ];
  static const List<String> _scoreOptions = <String>[
    '全部',
    '免费',
    '0-50',
    '50-100',
    '100+',
  ];
  static const List<String> _timeOptions = <String>[
    '全部',
    '今天',
    '本周',
    '周末',
  ];
  static const List<String> _distanceOptions = <String>[
    '不限',
    '3km内',
    '5km内',
    '10km内',
  ];

  final TextEditingController _searchController = TextEditingController();
  List<ActivityItem> _allActivities = <ActivityItem>[];
  List<ActivityItem> _activities = <ActivityItem>[];
  bool _loading = true;
  String? _loadError;
  String _sortBy = '';
  String _sortOrder = '';
  int _bottomTab = 0;
  Timer? _autoRefreshTimer;
  int _unreadCount = 0;
  bool _refreshingUnread = false;
  String _selectedType = '全部';
  String _selectedPrice = '全部';
  String _selectedTime = '全部';
  String _selectedDistance = '不限';

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

  int get _manageTodoCount {
    final int? userId = widget.sessionController.session?.userId;
    if (userId == null) return 0;
    return _allActivities
        .where((ActivityItem item) => item.creatorId == userId)
        .fold<int>(
          0,
          (int sum, ActivityItem item) =>
              sum + item.pendingCount + item.quitRequestedCount,
        );
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
      setState(() {
        _allActivities = list;
        _activities = _applyFilters(list);
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _allActivities = <ActivityItem>[];
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
      setState(() {
        _allActivities = list;
        _activities = _applyFilters(list);
      });
    } catch (_) {}
  }

  List<ActivityItem> _applyFilters(List<ActivityItem> source) {
    return source.where((ActivityItem item) {
      final String merged =
          '${item.name} ${(item.description ?? '')}'.toLowerCase();
      if (_selectedType != '全部' &&
          !merged.contains(_selectedType.toLowerCase())) {
        return false;
      }
      final num score = item.contractAmount;
      if (_selectedPrice == '免费' && score > 0) {
        return false;
      }
      if (_selectedPrice == '0-50' && (score < 0 || score > 50)) {
        return false;
      }
      if (_selectedPrice == '50-100' && (score <= 50 || score > 100)) {
        return false;
      }
      if (_selectedPrice == '100+' && score <= 100) {
        return false;
      }
      final DateTime? time = DateTime.tryParse(item.activityDate);
      if (_selectedTime != '全部' && time != null) {
        final DateTime now = DateTime.now();
        final DateTime today = DateTime(now.year, now.month, now.day);
        final DateTime date = DateTime(time.year, time.month, time.day);
        if (_selectedTime == '今天' && date != today) {
          return false;
        }
        if (_selectedTime == '本周') {
          final int diff = date.difference(today).inDays;
          if (diff < 0 || diff > 6) {
            return false;
          }
        }
        if (_selectedTime == '周末' &&
            date.weekday != DateTime.saturday &&
            date.weekday != DateTime.sunday) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _openFilterSheet() async {
    final _HomeFilterSelection? result = await showModalBottomSheet<_HomeFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _HomeFilterBottomSheet(
          typeOptions: _typeOptions,
          priceOptions: _scoreOptions,
          timeOptions: _timeOptions,
          distanceOptions: _distanceOptions,
          initialSelection: _HomeFilterSelection(
            type: _selectedType,
            price: _selectedPrice,
            time: _selectedTime,
            distance: _selectedDistance,
          ),
        );
      },
    );
    if (result == null) return;
    setState(() {
      _selectedType = result.type;
      _selectedPrice = result.price;
      _selectedTime = result.time;
      _selectedDistance = result.distance;
      _activities = _applyFilters(_allActivities);
    });
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
      _showMessage('本次未消耗积分，你可以稍后再决定');
      return;
    }
    try {
      await ApiService.instance.joinActivity(
        activityId: activity.id,
        userId: userId,
      );
      _showMessage('积分确认完成，报名申请已提交');
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
              '预计返还: ${preview.refundAmount} 积分\n'
              '扣除积分: ${preview.penaltyAmount}\n\n'
              '确认后将进入积分确认页。',
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
          ),
        ),
      );
      if (paid != true) {
        _showMessage('本次未处理退出申请');
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
    final String ruleText = _buildScoreRuleSummary(activity);
    final bool? agreed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(i18n.tr('confirmJoinTitle')),
          content: Text(
            '确认报名这个活动吗？本次会先确认消耗积分，再提交报名申请。\n\n'
            '$ruleText',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(i18n.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('去确认积分'),
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
        ),
      ),
    );
    return paid == true;
  }

  bool _canOpenChat(ActivityItem activity) {
    final int? userId = widget.sessionController.session?.userId;
    if (userId == null) {
      return false;
    }
    return activity.creatorId == userId || activity.joinStatus == 'approved';
  }

  void _openChat(ActivityItem activity) {
    if (!_canOpenChat(activity)) {
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
    ).then((_) => _refreshUnreadCount());
  }

  String _buildScoreRuleSummary(ActivityItem activity) {
    final String minuteRule =
        '1. 活动开始前 ${activity.refundBeforeMinutes} 分钟内退出，返还 ${(activity.refundBeforeMinutesRate * 100).toStringAsFixed(0)}% 的积分';
    final String hourRule =
        '2. 活动前 ${activity.refundBeforeMinutes} 分钟到 ${activity.refundBeforeHours} 小时之间退出，返还 ${(activity.refundBeforeHoursRate * 100).toStringAsFixed(0)}% 的积分';
    final String earlyRule =
        '3. 活动前超过 ${activity.refundBeforeHours} 小时退出，返还 ${(activity.refundBeforeEarlyRate * 100).toStringAsFixed(0)}% 的积分';
    return '积分规则：\n$minuteRule\n$hourRule\n$earlyRule';
  }

  void _showSortSheet() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '排序',
      barrierColor: const Color(0x22000000),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (BuildContext context, _, __) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 52, 58, 0),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.sort_rounded),
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
                        dense: true,
                        leading: const Icon(Icons.payments_outlined),
                        title: const Text('积分从高到低'),
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
                        dense: true,
                        leading: const Icon(Icons.event_available_outlined),
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
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder:
          (BuildContext context, Animation<double> animation, _, Widget child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
            alignment: Alignment.topRight,
            child: child,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF6A5AE0), Color(0xFF9D50BB)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x336A5AE0),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: _ScaleTap(
          onTap: () => _joinActivity(activity),
          borderRadius: BorderRadius.circular(26),
          child: SizedBox(
            height: 42,
            child: Center(
              child: Text(
                widget.localization.tr('joinNow'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4E8F3)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x16000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[Color(0xFF6A5AE0), Color(0xFF8FD3F4)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  /*
  Widget _buildHomeBody() {
    final ActivityItem? featured = _activities.isNotEmpty ? _activities.first : null;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFFF7F8FF), Color(0xFFF4F7FF), Color(0xFFFDFDFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: _HomeInspirationBanner(
                featured: featured,
                onJoin: featured == null ? null : () => _joinActivity(featured),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '搜点什么？比如：夜爬 / 羽毛球 / 看电影',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _loadActivities(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: <Color>[
                            Color(0xFF7160EF),
                            Color(0xFF9E66F2),
                          ],
                        ),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x337160EF),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _openFilterSheet,
                          child: const Icon(Icons.tune_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: _loadActivities,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: const BorderSide(color: Color(0xFFC8CCDF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: const Icon(
                        Icons.search,
                        size: 20,
                        color: Color(0xFF636985),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Text(
                '活动动态',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF303040),
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_loadError != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 44,
                        color: Color(0xFF8E8FA7),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '活动加载失败',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loadActivities,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('重新加载'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_activities.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  '暂时没有匹配到活动，换个关键词试试',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((
                  BuildContext context,
                  int index,
                ) {
                  final ActivityItem item = _activities[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HomeActivityCard(
                      activity: item,
                      action: _buildAction(item),
                      onChat: () => _openChat(item),
                    ),
                  );
                }, childCount: _activities.length),
              ),
            ),
        ],
      ),
    );
  }
  */

  Widget _buildHomeBody() {
    final List<Widget> slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: _HomeBannerCarousel(
            activities: _activities,
            onJoin: _joinActivity,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜点什么？比如：夜爬 / 羽毛球 / 看电影',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _loadActivities(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 46,
                height: 46,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF7160EF), Color(0xFF9E66F2)],
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _openFilterSheet,
                      child: const Icon(Icons.tune_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 46,
                height: 46,
                child: OutlinedButton(
                  onPressed: _loadActivities,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: Color(0xFFC8CCDF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  child: const Icon(
                    Icons.search,
                    size: 20,
                    color: Color(0xFF636985),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Text(
            '活动动态',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF303040),
            ),
          ),
        ),
      ),
    ];

    if (_loading) {
      slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (_loadError != null) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              _loadError!,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
        ),
      );
    } else if (_activities.isEmpty) {
      slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              '暂时没有匹配到活动，换个关键词试试',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
        ),
      );
    } else {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final ActivityItem item = _activities[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HomeActivityCard(
                    activity: item,
                    action: _buildAction(item),
                    onChat: () => _openChat(item),
                  ),
                );
              },
              childCount: _activities.length,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFFF7F8FF), Color(0xFFF4F7FF), Color(0xFFFDFDFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: slivers,
      ),
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
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                IconButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/manage',
                  ).then((_) => _loadActivities()),
                  icon: const Icon(Icons.manage_accounts),
                ),
                if (_manageTodoCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _manageTodoCount > 99 ? '99' : '$_manageTodoCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
      body: _bottomTab == 0
          ? _buildHomeBody()
          : _bottomTab == 1
              ? PlazaScreen(sessionController: widget.sessionController)
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

class _HomeFilterSelection {
  const _HomeFilterSelection({
    required this.type,
    required this.price,
    required this.time,
    required this.distance,
  });

  final String type;
  final String price;
  final String time;
  final String distance;
}

class _HomeBannerCarousel extends StatefulWidget {
  const _HomeBannerCarousel({
    required this.activities,
    required this.onJoin,
  });

  final List<ActivityItem> activities;
  final Function(ActivityItem) onJoin;

  @override
  State<_HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<_HomeBannerCarousel> {
  final PageController _controller = PageController();
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || widget.activities.isEmpty) return;
      _index = (_index + 1) % widget.activities.length;
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activities.isEmpty) return const SizedBox();

    final int count = widget.activities.length.clamp(0, 5);
    return Column(
      children: <Widget>[
        SizedBox(
          height: 162,
          child: PageView.builder(
            controller: _controller,
            itemCount: count,
            onPageChanged: (int i) => setState(() => _index = i),
            itemBuilder: (_, int i) {
              final ActivityItem item = widget.activities[i];
              return _BannerCard(
                activity: item,
                onJoin: () => widget.onJoin(item),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(
            count,
            (int i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _index == i ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _index == i ? const Color(0xFF6A5AE0) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.activity, required this.onJoin});

  final ActivityItem activity;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final int joined = activity.approvedCount;
    final int remain = (4 - joined).clamp(0, 4);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF6A5AE0), Color(0xFF8FD3F4), Color(0xFFF39BD5)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '🔥 今日推荐',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            activity.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '还差 $remain 人成行',
            style: const TextStyle(color: Colors.white70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: <Widget>[
              _AvatarStack(activity: activity),
              const Spacer(),
              ElevatedButton(
                onPressed: onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6A5AE0),
                ),
                child: const Text('加入'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatefulWidget {
  const _AvatarStack({required this.activity});

  final ActivityItem activity;

  @override
  State<_AvatarStack> createState() => _AvatarStackState();
}

class _AvatarStackState extends State<_AvatarStack> {
  final ScrollController _controller = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_controller.hasClients) return;
      final double max = _controller.position.maxScrollExtent;
      if (max <= 0) return;
      final double next =
          _controller.offset >= max - 4 ? 0 : _controller.offset + 42;
      _controller.animateTo(
        next,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int count = widget.activity.approvedCount;
    final List<String> names = widget.activity.approvedParticipantNames;
    final List<String> avatars = widget.activity.approvedParticipantAvatars;
    final int showCount = math.max(count, names.length).clamp(0, 12).toInt();
    if (showCount == 0) {
      return const SizedBox(
        width: 86,
        height: 32,
        child: Center(
          child: Text(
            '等待报名',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ),
      );
    }

    return SizedBox(
      width: 116,
      height: 34,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: showCount,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (BuildContext context, int index) {
          final String name =
              index < names.length ? names[index] : '成员${index + 1}';
          final String? avatar = index < avatars.length ? avatars[index] : null;
          return Tooltip(
            message: name,
            child: AvatarBadge(
              name: name,
              avatarId: avatar,
              radius: 15,
              showRing: true,
            ),
          );
        },
      ),
    );
  }
}

class _HomeActivityCard extends StatelessWidget {
  const _HomeActivityCard({
    required this.activity,
    required this.action,
    required this.onChat,
  });

  final ActivityItem activity;
  final Widget action;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final int joined = activity.approvedCount;
    final int remain = (4 - joined).clamp(0, 4);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activity.name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            activity.description ?? '这个局正在等你加入',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _AvatarStack(activity: activity),
              const SizedBox(width: 8),
              Text('还差 $remain 人'),
              const Spacer(),
              Text('${activity.contractAmount} 积分'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: action),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onChat,
                child: const Text('聊天'),
              )
            ],
          )
        ],
      ),
    );
  }
}

class _HomeFilterBottomSheet extends StatefulWidget {
  const _HomeFilterBottomSheet({
    required this.typeOptions,
    required this.priceOptions,
    required this.timeOptions,
    required this.distanceOptions,
    required this.initialSelection,
  });
  final List<String> typeOptions;
  final List<String> priceOptions;
  final List<String> timeOptions;
  final List<String> distanceOptions;
  final _HomeFilterSelection initialSelection;
  @override
  State<_HomeFilterBottomSheet> createState() => _HomeFilterBottomSheetState();
}
class _HomeFilterBottomSheetState extends State<_HomeFilterBottomSheet> {
  late String _type;
  late String _price;
  late String _time;
  late String _distance;
  @override
  void initState() {
    super.initState();
    _type = widget.initialSelection.type;
    _price = widget.initialSelection.price;
    _time = widget.initialSelection.time;
    _distance = widget.initialSelection.distance;
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    '\u7b5b\u9009\u6d3b\u52a8\u5c40',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _type = widget.typeOptions.first;
                        _price = widget.priceOptions.first;
                        _time = widget.timeOptions.first;
                        _distance = widget.distanceOptions.first;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6D5EF9),
                    ),
                    child: const Text(
                      '\u91cd\u7f6e',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _FilterSection(
                title: '\u6d3b\u52a8\u7c7b\u578b',
                child: ViscousSegmentedControl(
                  options: widget.typeOptions,
                  value: _type,
                  onChanged: (String value) => setState(() => _type = value),
                ),
              ),
              _FilterSection(
                title: '\u79ef\u5206\u533a\u95f4',
                child: ViscousSegmentedControl(
                  options: widget.priceOptions,
                  value: _price,
                  onChanged: (String value) => setState(() => _price = value),
                ),
              ),
              _FilterSection(
                title: '\u65f6\u95f4',
                child: ViscousSegmentedControl(
                  options: widget.timeOptions,
                  value: _time,
                  onChanged: (String value) => setState(() => _time = value),
                ),
              ),
              _FilterSection(
                title: '\u8ddd\u79bb',
                child: ViscousSegmentedControl(
                  options: widget.distanceOptions,
                  value: _distance,
                  onChanged: (String value) => setState(() => _distance = value),
                ),
              ),
              const SizedBox(height: 24),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF6A5AE0), Color(0xFF9D50BB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x4D6A5AE0),
                      blurRadius: 15,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: _ScaleTap(
                  onTap: () {
                    Navigator.pop(
                      context,
                      _HomeFilterSelection(
                        type: _type,
                        price: _price,
                        time: _time,
                        distance: _distance,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    alignment: Alignment.center,
                    child: const Text(
                      '\u786e \u8ba4',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class ViscousSegmentedControl extends StatefulWidget {
  const ViscousSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;
  @override
  State<ViscousSegmentedControl> createState() => _ViscousSegmentedControlState();
}
class _ViscousSegmentedControlState extends State<ViscousSegmentedControl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Tween<double> _positionTween;
  late Animation<double> _positionAnimation;
  @override
  void initState() {
    super.initState();
    final int initialIndex = widget.options.indexOf(widget.value);
    final double initialAlignmentX = _getAlignmentX(initialIndex < 0 ? 0 : initialIndex);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _positionTween = Tween<double>(
      begin: initialAlignmentX,
      end: initialAlignmentX,
    );
    _positionAnimation = _buildPositionAnimation();
  }
  @override
  void didUpdateWidget(covariant ViscousSegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final int newIndex = widget.options.indexOf(widget.value);
      final double newAlignmentX = _getAlignmentX(newIndex < 0 ? 0 : newIndex);
      _positionTween = Tween<double>(
        begin: _positionAnimation.value,
        end: newAlignmentX,
      );
      _positionAnimation = _buildPositionAnimation();
      _controller
        ..reset()
        ..forward();
    }
  }
  Animation<double> _buildPositionAnimation() {
    return _positionTween.animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    )..addListener(() {
        setState(() {});
      });
  }
  double _getAlignmentX(int index) {
    if (widget.options.length <= 1) {
      return 0;
    }
    return -1 + (index * 2 / (widget.options.length - 1));
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final double rawProgress = _controller.view.value;
    final double dragDistance = _positionTween.end! - _positionTween.begin!;
    double viscosity = math.sin(rawProgress * math.pi);
    if (_controller.isCompleted ||
        _controller.isDismissed ||
        dragDistance.abs() < 0.01) {
      viscosity = 0;
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double totalWidth = constraints.maxWidth;
        const double height = 50;
        final double itemWidth = (totalWidth - 8) / widget.options.length;
        final double currentAlignX = _positionAnimation.value;
        void selectByDx(double dx) {
          final int index = ((dx - 4) / itemWidth)
              .round()
              .clamp(0, widget.options.length - 1);
          widget.onChanged(widget.options[index]);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (DragUpdateDetails details) {
            selectByDx(details.localPosition.dx);
          },
          child: Container(
            height: height,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment(currentAlignX, 0),
                  child: CustomPaint(
                    size: Size(itemWidth, height - 8),
                    painter: DropletPainter(
                      viscosity: viscosity,
                      direction: dragDistance.sign,
                    ),
                  ),
                ),
                Row(
                  children: widget.options.map((String option) {
                    final bool selected = option == widget.value;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onChanged(option),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFF20163A)
                                  : const Color(0xFF6B7280),
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 14,
                            ),
                            child: Text(option),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
class DropletPainter extends CustomPainter {
  DropletPainter({
    required this.viscosity,
    required this.direction,
  });
  final double viscosity;
  final double direction;
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Color(0xFFFFD976), Color(0xFFFFA86B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;
    final Path shadowPath = Path();
    final RRect shadowRect = RRect.fromRectAndRadius(
      Offset(0, 3) & Size(size.width, size.height),
      Radius.circular(size.height / 2),
    );
    shadowPath.addRRect(shadowRect);
    canvas.drawShadow(shadowPath, const Color(0x33FFB86B), 8, false);
    final Path path = Path();
    final double w = size.width;
    final double h = size.height;
    final double centerY = h / 2;
    final double radius = h / 2;
    if (viscosity.abs() < 0.001) {
      path.addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    } else {
      const double maxStretch = 16;
      final double headOffset = 2 * viscosity * direction;
      final double trailOffset = -maxStretch * viscosity * direction;
      final Offset topLeft = Offset(radius + headOffset, 0);
      final Offset bottomLeft = Offset(radius + headOffset, h);
      final Offset topRight = Offset(w - radius + headOffset, 0);
      final Offset bottomRight = Offset(w - radius + headOffset, h);
      if (direction > 0) {
        final Offset trailTip = Offset(headOffset + trailOffset, centerY);
        path.moveTo(topRight.dx, topRight.dy);
        path.arcToPoint(bottomRight, radius: Radius.circular(radius));
        path.lineTo(bottomLeft.dx, bottomLeft.dy);
        path.cubicTo(
          bottomLeft.dx - radius * 0.5,
          bottomLeft.dy,
          trailTip.dx + radius * 0.2,
          centerY + radius * 0.5,
          trailTip.dx,
          trailTip.dy,
        );
        path.cubicTo(
          trailTip.dx + radius * 0.2,
          centerY - radius * 0.5,
          topLeft.dx - radius * 0.5,
          topLeft.dy,
          topLeft.dx,
          topLeft.dy,
        );
        path.close();
      } else {
        final Offset trailTip = Offset(w + headOffset + trailOffset, centerY);
        path.moveTo(topLeft.dx, topLeft.dy);
        path.arcToPoint(
          bottomLeft,
          radius: Radius.circular(radius),
          clockwise: false,
        );
        path.lineTo(bottomRight.dx, bottomRight.dy);
        path.cubicTo(
          bottomRight.dx + radius * 0.5,
          bottomRight.dy,
          trailTip.dx - radius * 0.2,
          centerY + radius * 0.5,
          trailTip.dx,
          trailTip.dy,
        );
        path.cubicTo(
          trailTip.dx - radius * 0.2,
          centerY - radius * 0.5,
          topRight.dx + radius * 0.5,
          topRight.dy,
          topRight.dx,
          topRight.dy,
        );
        path.close();
      }
    }
    canvas.drawPath(path, paint);
    final Paint lightPaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..style = PaintingStyle.fill;
    final RRect lightRect = RRect.fromRectAndRadius(
      Offset(size.width - 16, 8) & const Size(10, 10),
      const Radius.circular(5),
    );
    canvas.save();
    canvas.translate(2 * viscosity * direction, 0);
    canvas.drawRRect(lightRect, lightPaint);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant DropletPainter oldDelegate) {
    return oldDelegate.viscosity != viscosity ||
        oldDelegate.direction != direction;
  }
}
class _ScaleTap extends StatefulWidget {
  const _ScaleTap({
    required this.child,
    required this.onTap,
    required this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: widget.borderRadius,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
