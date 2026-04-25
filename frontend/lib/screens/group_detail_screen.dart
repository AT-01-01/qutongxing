import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../widgets/avatar_badge.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({
    super.key,
    required this.activity,
    required this.currentUserId,
  });

  final ActivityItem activity;
  final int currentUserId;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  bool _loading = true;
  String? _error;
  List<ParticipantItem> _members = <ParticipantItem>[];
  UserProfile? _creatorProfile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<ParticipantItem> members =
          await ApiService.instance.getApprovedParticipants(widget.activity.id);
      UserProfile? creatorProfile;
      if (widget.activity.creatorId != null) {
        creatorProfile = await ApiService.instance.getUserProfile(
          userId: widget.activity.creatorId!,
        );
      }
      if (!mounted) return;
      setState(() {
        _members = members;
        _creatorProfile = creatorProfile;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_GroupMember> displayMembers = <_GroupMember>[
      if (_creatorProfile != null)
        _GroupMember(
          userId: widget.activity.creatorId ?? 0,
          name: _creatorProfile!.displayName?.trim().isNotEmpty == true
              ? _creatorProfile!.displayName!
              : (_creatorProfile!.username),
          avatar: _creatorProfile!.avatar,
          gender: _creatorProfile!.gender,
          realNameVerified: _creatorProfile!.realNameVerified,
          role: '群主',
        ),
      ..._members.map(
        (ParticipantItem item) => _GroupMember(
          userId: item.userId,
          name: item.username,
          avatar: item.avatar,
          gender: item.gender,
          realNameVerified: item.realNameVerified,
          role: item.userId == widget.currentUserId ? '我' : '群友',
        ),
      ),
    ].fold<List<_GroupMember>>(<_GroupMember>[], (
      List<_GroupMember> result,
      _GroupMember member,
    ) {
      if (result.any((_GroupMember item) => item.userId == member.userId)) {
        return result;
      }
      result.add(member);
      return result;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('群详情'),
        actions: <Widget>[
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFF4F6FF), Color(0xFFF9FBFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: <Color>[Color(0xFF6A5AE0), Color(0xFF8FD3F4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.activity.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.activity.description?.isNotEmpty == true
                                  ? widget.activity.description!
                                  : '这是本场活动的临时群，进来先认人再发车。',
                              style: const TextStyle(
                                color: Color(0xFFF0EDFF),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '群友 ${displayMembers.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 14,
                        children: displayMembers.map((_GroupMember member) {
                          return _MemberCard(member: member);
                        }).toList(),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _GroupMember {
  const _GroupMember({
    required this.userId,
    required this.name,
    required this.avatar,
    required this.gender,
    required this.realNameVerified,
    required this.role,
  });

  final int userId;
  final String name;
  final String? avatar;
  final String? gender;
  final bool realNameVerified;
  final String role;
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final _GroupMember member;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        children: <Widget>[
          AvatarBadge(
            name: member.name,
            avatarId: member.avatar,
            radius: 28,
            showRing: true,
          ),
          const SizedBox(height: 8),
          Text(
            member.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            member.realNameVerified ? '${member.role} · 已实名' : member.role,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
          if (member.gender?.trim().isNotEmpty == true)
            Text(
              member.gender!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6A5AE0),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
