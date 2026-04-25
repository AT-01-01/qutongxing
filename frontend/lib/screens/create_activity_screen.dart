import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../session_controller.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({
    super.key,
    required this.sessionController,
  });

  final SessionController sessionController;

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _refundBeforeMinutesController =
      TextEditingController(text: '10');
  final TextEditingController _refundBeforeMinutesRateController =
      TextEditingController(text: '0.5');
  final TextEditingController _refundBeforeHoursController =
      TextEditingController(text: '3');
  final TextEditingController _refundBeforeHoursRateController =
      TextEditingController(text: '0.8');
  final TextEditingController _refundBeforeEarlyRateController =
      TextEditingController(text: '1.0');
  final TextEditingController _lateArrivalWindowHoursController =
      TextEditingController(text: '2');
  final TextEditingController _lateArrivalPenaltyRateController =
      TextEditingController(text: '0.2');
  final TextEditingController _checkinDistanceController =
      TextEditingController(text: '120');
  bool _allowMemberDirectMessage = true;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _imageUrlController.dispose();
    _refundBeforeMinutesController.dispose();
    _refundBeforeMinutesRateController.dispose();
    _refundBeforeHoursController.dispose();
    _refundBeforeHoursRateController.dispose();
    _refundBeforeEarlyRateController.dispose();
    _lateArrivalWindowHoursController.dispose();
    _lateArrivalPenaltyRateController.dispose();
    _checkinDistanceController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 3)),
      initialDate: _selectedDateTime,
    );
    if (date == null || !mounted) {
      return;
    }
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    final int? userId = widget.sessionController.session?.userId;
    if (userId == null) {
      _showMessage('请先登录');
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    if (_nameController.text.trim().isEmpty ||
        _amountController.text.trim().isEmpty) {
      _showMessage('活动名称和参与积分不能为空');
      return;
    }

    setState(() => _loading = true);
    try {
      // 后端使用 LocalDateTime.parse 解析活动时间，因此这里必须传 `yyyy-MM-ddTHH:mm:ss` 格式。
      final String datePayload = DateFormat(
        "yyyy-MM-dd'T'HH:mm:ss",
      ).format(_selectedDateTime);
      await ApiService.instance.createActivity(
        userId: userId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        activityDate: datePayload,
        contractAmount: _amountController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        refundBeforeMinutes: int.tryParse(
          _refundBeforeMinutesController.text.trim(),
        ),
        refundBeforeMinutesRate: num.tryParse(
          _refundBeforeMinutesRateController.text.trim(),
        ),
        refundBeforeHours: int.tryParse(_refundBeforeHoursController.text.trim()),
        refundBeforeHoursRate: num.tryParse(
          _refundBeforeHoursRateController.text.trim(),
        ),
        refundBeforeEarlyRate: num.tryParse(
          _refundBeforeEarlyRateController.text.trim(),
        ),
        lateArrivalWindowHours: int.tryParse(
          _lateArrivalWindowHoursController.text.trim(),
        ),
        lateArrivalPenaltyRate: num.tryParse(
          _lateArrivalPenaltyRateController.text.trim(),
        ),
        checkinDistanceMeters: int.tryParse(_checkinDistanceController.text.trim()),
        allowMemberDirectMessage: _allowMemberDirectMessage,
      );
      if (!mounted) return;
      _showMessage('活动创建成功');
      Navigator.pop(context);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final String displayTime = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(_selectedDateTime);
    return Scaffold(
      appBar: AppBar(title: const Text('创建活动')),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF6D5EF9), Color(0xFF8F7CFF)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '发布新的活动局',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '填写完整信息后，系统将自动同步到活动大厅',
                    style: TextStyle(color: Color(0xFFEDE9FE)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '活动名称',
                        prefixIcon: Icon(Icons.title_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: '活动描述',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '参与积分',
                        prefixIcon: Icon(Icons.stars_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: '图片 URL（可选）',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '退出与打卡规则（团长可设置）',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _refundBeforeHoursController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '活动前小时数',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _refundBeforeHoursRateController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: '返还比例(0-1)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _refundBeforeEarlyRateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '前3小时以前返还比例(0-1)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _refundBeforeMinutesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '活动前分钟数',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _refundBeforeMinutesRateController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: '返还比例(0-1)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _lateArrivalWindowHoursController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '开始后到达窗口(小时)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _lateArrivalPenaltyRateController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: '迟到扣除比例(0-1)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _checkinDistanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '打卡接近距离(米)',
                        prefixIcon: Icon(Icons.pin_drop_outlined),
                      ),
                    ),
                    SwitchListTile(
                      value: _allowMemberDirectMessage,
                      onChanged: (bool value) {
                        setState(() => _allowMemberDirectMessage = value);
                      },
                      title: const Text('允许团员互相私信'),
                      subtitle: const Text('可在活动群内查看成员并发起私聊（后续扩展）'),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: _pickDateTime,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFDDE2FF)),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: Color(0xFF6D5EF9),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    '活动时间',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    displayTime,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _submit,
                        icon: const Icon(Icons.rocket_launch_outlined),
                        label: Text(_loading ? '提交中...' : '发布活动'),
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
