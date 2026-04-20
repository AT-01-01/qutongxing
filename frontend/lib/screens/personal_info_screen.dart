import 'package:flutter/material.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({
    super.key,
    required this.displayName,
    required this.gender,
    required this.city,
    required this.address,
    required this.bio,
  });

  final String displayName;
  final String gender;
  final String city;
  final String address;
  final String bio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('个人信息')),
      body: ListView(
        children: <Widget>[
          Container(
            height: 140,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Color(0xFF6D5EF9), Color(0xFF8B80FF)],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -34),
            child: Column(
              children: <Widget>[
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0xFFEDE9FE),
                    child: Text(
                      displayName.isEmpty ? '趣' : displayName.characters.first,
                      style: const TextStyle(
                        color: Color(0xFF5B21B6),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text('@$displayName', style: const TextStyle(color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: <Widget>[
                    _InfoRow(label: '性别', value: gender),
                    _InfoRow(label: '所在地', value: city),
                    _InfoRow(label: '详细地址', value: address),
                    _InfoRow(label: '个人简介', value: bio, multiLine: true),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.multiLine = false,
  });

  final String label;
  final String value;
  final bool multiLine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment:
            multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
