import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../session_controller.dart';

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
      if (delta.isEmpty || !mounted) {
        return;
      }
      setState(() {
        _messages = <ChatMessage>[..._messages, ...delta];
        _lastMessageId = _messages.last.id;
      });
      await _markConversationRead();
      _scrollToBottom();
    } catch (_) {
      // 轮询静默失败，避免干扰聊天输入。
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
    setState(() => _locating = true);
    try {
      final LocationPermission permission = await _ensureLocationPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('未获得定位权限，无法打卡');
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
      _showMessage('已自动共享当前位置并完成打卡');
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
      throw Exception('定位服务未开启');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  Future<void> _loadLocations() async {
    final int? userId = _userId;
    if (userId == null) {
      return;
    }
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
        try {
          _mapController.move(LatLng(first.latitude, first.longitude), 14);
        } catch (_) {}
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _markConversationRead() async {
    final int? userId = _userId;
    final int? lastId = _lastMessageId;
    if (userId == null || lastId == null || lastId <= 0) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chat_last_read_${userId}_${widget.activity.id}', lastId);
  }

  @override
  Widget build(BuildContext context) {
    final int? userId = _userId;
    return Scaffold(
      appBar: AppBar(
        title: Text('活动交流 · ${widget.activity.name}'),
      ),
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: const Color(0xFFF3F4F6),
            child: const Text(
              '已支持活动群聊。点击“共享位置并打卡”后会自动获取定位并在地图展示团员位置。',
              style: TextStyle(fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _locating ? null : _shareLocationAndCheckin,
                icon: const Icon(Icons.my_location_outlined),
                label: Text(_locating ? '定位中...' : '共享位置并打卡'),
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: _locations.isEmpty
                  ? const Center(child: Text('暂无可展示的位置数据'))
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(
                          _locations.first.latitude,
                          _locations.first.longitude,
                        ),
                        initialZoom: 14,
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
                              height: 58,
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      p.username,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  Icon(
                                    Icons.location_on,
                                    color: p.attended
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626),
                                    size: 26,
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
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ChatMessage msg = _messages[index];
                      final bool mine = msg.senderId == userId;
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: mine
                                ? const Color(0xFFDBEAFE)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                msg.senderName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(msg.content),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: '输入消息...',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sending ? null : _send,
                    child: Text(_sending ? '发送中...' : '发送'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
