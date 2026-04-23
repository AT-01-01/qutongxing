import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../session_controller.dart';
import '../widgets/avatar_badge.dart';
import 'group_detail_screen.dart';

class ActivityChatScreen extends StatefulWidget {
  const ActivityChatScreen({
    super.key,
    required this.activity,
    required this.sessionController,
  });

  final ActivityItem activity;
  final SessionController sessionController;

  @override
  State<ActivityChatScreen> createState() => _ActivityChatScreenState();
}

class _ActivityChatScreenState extends State<ActivityChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MapController _mapController = MapController();
  List<ChatMessage> _messages = <ChatMessage>[];
  List<ParticipantLocation> _locations = <ParticipantLocation>[];
  Timer? _pollingTimer;
  bool _loading = true;
  bool _sending = false;
  bool _locating = false;
  bool _pollingInFlight = false;
  bool _locationEnabled = true;
  int? _lastMessageId;

  int? get _userId => widget.sessionController.session?.userId;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollNewMessages();
    });
  }

  @override
  void dispose() {
    _markConversationRead();
    _pollingTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final int? userId = _userId;
    if (userId == null) return;
    try {
      final List<ChatMessage> data = await ApiService.instance.getChatMessages(
        activityId: widget.activity.id,
        userId: userId,
      );
      if (!mounted) return;
      setState(() {
        _messages = data;
        _lastMessageId = data.isNotEmpty ? data.last.id : null;
        _loading = false;
      });
      await _markConversationRead();
      await _loadLocations();
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage(e.message);
    }
  }

  Future<void> _pollNewMessages() async {
    if (_pollingInFlight) return;
    final int? userId = _userId;
    if (userId == null) return;
    _pollingInFlight = true;
    try {
      final List<ChatMessage> delta = await ApiService.instance.getChatMessages(
        activityId: widget.activity.id,
        userId: userId,
        afterId: _lastMessageId,
      );
      if (delta.isEmpty || !mounted) return;
      setState(() {
        _messages = <ChatMessage>[..._messages, ...delta];
        _lastMessageId = _messages.last.id;
      });
      await _markConversationRead();
      _scrollToBottom();
    } catch (_) {
      // Keep silent during polling.
    } finally {
      _pollingInFlight = false;
    }
  }

  Future<void> _send() async {
    final int? userId = _userId;
    if (userId == null) return;
    final String content = _inputController.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    try {
      final ChatMessage message = await ApiService.instance.sendChatMessage(
        activityId: widget.activity.id,
        userId: userId,
        content: content,
      );
      if (!mounted) return;
      setState(() {
        _inputController.clear();
        _messages = <ChatMessage>[..._messages, message];
        _lastMessageId = message.id;
      });
      await _markConversationRead();
      _scrollToBottom();
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _shareLocationAndCheckin() async {
    final int? userId = _userId;
    if (userId == null) return;
    if (!_locationEnabled) {
      _showMessage('请先在右上角打开定位模式');
      return;
    }
    setState(() => _locating = true);
    try {
      final LocationPermission permission = await _ensureLocationPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('没有定位权限，暂时无法打卡');
        return;
      }

      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await ApiService.instance.shareLocation(
        activityId: widget.activity.id,
        userId: userId,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      await _loadLocations();
      await ApiService.instance.autoCheckin(
        activityId: widget.activity.id,
        userId: userId,
      );
      _showMessage('已共享当前位置并完成自动打卡');
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('定位失败，请检查设备定位服务');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<LocationPermission> _ensureLocationPermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('location-disabled');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  Future<void> _loadLocations() async {
    final int? userId = _userId;
    if (userId == null || !_locationEnabled) return;
    try {
      final List<ParticipantLocation> data =
          await ApiService.instance.getParticipantLocations(
        activityId: widget.activity.id,
        userId: userId,
      );
      if (!mounted) return;
      setState(() => _locations = data);
      if (data.isNotEmpty) {
        final ParticipantLocation first = data.first;
        _mapController.move(LatLng(first.latitude, first.longitude), 13.8);
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
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

  Future<void> _markConversationRead() async {
    final int? userId = _userId;
    final int? lastId = _lastMessageId;
    if (userId == null || lastId == null || lastId <= 0) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chat_last_read_${userId}_${widget.activity.id}', lastId);
  }

  Future<void> _openGroupDetail() async {
    final int? userId = _userId;
    if (userId == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => GroupDetailScreen(
          activity: widget.activity,
          currentUserId: userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int? userId = _userId;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.name),
        actions: <Widget>[
          IconButton(
            tooltip: _locationEnabled ? '关闭定位视图' : '开启定位视图',
            onPressed: () {
              setState(() => _locationEnabled = !_locationEnabled);
              if (_locationEnabled) {
                _loadLocations();
              }
            },
            icon: Icon(
              _locationEnabled
                  ? Icons.location_on_rounded
                  : Icons.location_off_rounded,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == 'detail') {
                _openGroupDetail();
              }
            },
            itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'detail',
                child: Text('群详情'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFF3F6FF), Color(0xFFF9FBFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF6A5AE0), Color(0xFF8FD3F4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          '活动群聊',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _locationEnabled
                              ? '定位已开启，可以共享位置并查看群友打卡情况。'
                              : '定位已关闭，现在是纯聊天模式。',
                          style: const TextStyle(
                            color: Color(0xFFF0EDFF),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Switch(
                    value: _locationEnabled,
                    onChanged: (bool value) {
                      setState(() => _locationEnabled = value);
                      if (value) {
                        _loadLocations();
                      }
                    },
                    activeColor: const Color(0xFF6A5AE0),
                    activeTrackColor: Colors.white,
                  ),
                ],
              ),
            ),
            if (_locationEnabled) ...<Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _locating ? null : _shareLocationAndCheckin,
                    icon: const Icon(Icons.my_location_outlined),
                    label: Text(_locating ? '定位中...' : '共享位置并打卡'),
                  ),
                ),
              ),
              Container(
                height: 188,
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _locations.isEmpty
                      ? const Center(child: Text('还没有可展示的定位数据'))
                      : FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(
                              _locations.first.latitude,
                              _locations.first.longitude,
                            ),
                            initialZoom: 13.8,
                          ),
                          children: <Widget>[
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.qutongxing',
                            ),
                            MarkerLayer(
                              markers: _locations.map((ParticipantLocation p) {
                                return Marker(
                                  point: LatLng(p.latitude, p.longitude),
                                  width: 120,
                                  height: 64,
                                  child: Column(
                                    children: <Widget>[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          p.username,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      Icon(
                                        Icons.location_on_rounded,
                                        color: p.attended
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFFEF4444),
                                        size: 30,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                ),
              ),
            ],
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: _messages.length,
                      itemBuilder: (BuildContext context, int index) {
                        final ChatMessage msg = _messages[index];
                        final bool mine = msg.senderId == userId;
                        return Align(
                          alignment:
                              mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 280),
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: mine
                                  ? const LinearGradient(
                                      colors: <Color>[
                                        Color(0xFF6A5AE0),
                                        Color(0xFF8C7BFF),
                                      ],
                                    )
                                  : null,
                              color: mine ? null : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x0F000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                if (!mine)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: AvatarBadge(
                                      name: msg.senderName,
                                      radius: 16,
                                    ),
                                  ),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        msg.senderName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: mine
                                              ? const Color(0xFFE9E7FF)
                                              : const Color(0xFF6B7280),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        msg.content,
                                        style: TextStyle(
                                          color: mine
                                              ? Colors.white
                                              : const Color(0xFF111827),
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE6EAF5))),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: '说点什么，组局气氛靠你了',
                          filled: true,
                          fillColor: const Color(0xFFF5F6FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0xFF6A5AE0), Color(0xFF9D50BB)],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: _sending ? null : _send,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(72, 48),
                        ),
                        child: Text(_sending ? '发送中' : '发送'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
