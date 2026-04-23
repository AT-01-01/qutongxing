class UserSession {
  UserSession({
    required this.userId,
    required this.username,
    required this.email,
    required this.phone,
    required this.token,
  });

  final int userId;
  final String username;
  final String? email;
  final String? phone;
  final String token;

  factory UserSession.fromLoginPayload(Map<String, dynamic> payload) {
    return UserSession(
      userId: payload['userId'] as int,
      username: (payload['username'] ?? '') as String,
      email: payload['email'] as String?,
      phone: payload['phone'] as String?,
      token: (payload['token'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'username': username,
      'email': email,
      'phone': phone,
      'token': token,
    };
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: json['userId'] as int,
      username: (json['username'] ?? '') as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      token: (json['token'] ?? '') as String,
    );
  }
}

class UserProfile {
  UserProfile({
    required this.userId,
    required this.username,
    this.displayName,
    this.gender,
    this.bio,
    this.city,
    this.address,
    this.avatar,
    this.email,
    this.phone,
  });

  final int userId;
  final String username;
  final String? displayName;
  final String? gender;
  final String? bio;
  final String? city;
  final String? address;
  final String? avatar;
  final String? email;
  final String? phone;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as int,
      username: (json['username'] ?? '') as String,
      displayName: json['displayName'] as String?,
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      city: json['city'] as String?,
      address: json['address'] as String?,
      avatar: json['avatar'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

class ActivityItem {
  ActivityItem({
    required this.id,
    required this.name,
    required this.description,
    required this.activityDate,
    required this.contractAmount,
    this.creatorId,
    required this.creatorName,
    this.imageBase64,
    this.joinStatus,
    this.pendingCount = 0,
    this.quitRequestedCount = 0,
    this.approvedCount = 0,
    this.refundBeforeMinutes = 10,
    this.refundBeforeMinutesRate = 0.5,
    this.refundBeforeHours = 3,
    this.refundBeforeHoursRate = 0.8,
    this.refundBeforeEarlyRate = 1.0,
    this.lateArrivalWindowHours = 2,
    this.lateArrivalPenaltyRate = 0.2,
    this.checkinDistanceMeters = 120,
    this.allowMemberDirectMessage = true,
  });

  final int id;
  final String name;
  final String? description;
  final String activityDate;
  final num contractAmount;
  final int? creatorId;
  final String creatorName;
  final String? imageBase64;
  final String? joinStatus;
  final int pendingCount;
  final int quitRequestedCount;
  final int approvedCount;
  final int refundBeforeMinutes;
  final num refundBeforeMinutesRate;
  final int refundBeforeHours;
  final num refundBeforeHoursRate;
  final num refundBeforeEarlyRate;
  final int lateArrivalWindowHours;
  final num lateArrivalPenaltyRate;
  final int checkinDistanceMeters;
  final bool allowMemberDirectMessage;

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      description: json['description'] as String?,
      activityDate: (json['activityDate'] ?? '') as String,
      contractAmount: (json['contractAmount'] ?? 0) as num,
      creatorId: json['creatorId'] as int?,
      creatorName: (json['creatorName'] ?? '未知') as String,
      imageBase64: json['imageBase64'] as String?,
      joinStatus: json['joinStatus'] as String?,
      pendingCount: (json['pendingCount'] ?? 0) as int,
      quitRequestedCount: (json['quitRequestedCount'] ?? 0) as int,
      approvedCount: (json['approvedCount'] ?? 0) as int,
      refundBeforeMinutes: (json['refundBeforeMinutes'] ?? 10) as int,
      refundBeforeMinutesRate: (json['refundBeforeMinutesRate'] ?? 0.5) as num,
      refundBeforeHours: (json['refundBeforeHours'] ?? 3) as int,
      refundBeforeHoursRate: (json['refundBeforeHoursRate'] ?? 0.8) as num,
      refundBeforeEarlyRate: (json['refundBeforeEarlyRate'] ?? 1.0) as num,
      lateArrivalWindowHours: (json['lateArrivalWindowHours'] ?? 2) as int,
      lateArrivalPenaltyRate: (json['lateArrivalPenaltyRate'] ?? 0.2) as num,
      checkinDistanceMeters: (json['checkinDistanceMeters'] ?? 120) as int,
      allowMemberDirectMessage: (json['allowMemberDirectMessage'] ?? true) as bool,
    );
  }
}

class ParticipantItem {
  ParticipantItem({
    required this.id,
    required this.userId,
    required this.username,
    this.avatar,
    required this.email,
    required this.phone,
    required this.status,
    required this.quitRequested,
  });

  final int id;
  final int userId;
  final String username;
  final String? avatar;
  final String? email;
  final String? phone;
  final String status;
  final bool quitRequested;

  factory ParticipantItem.fromJson(Map<String, dynamic> json) {
    return ParticipantItem(
      id: json['id'] as int,
      userId: json['userId'] as int,
      username: (json['username'] ?? '') as String,
      avatar: json['avatar'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      status: (json['status'] ?? '') as String,
      quitRequested: (json['quitRequested'] ?? false) as bool,
    );
  }
}

class QuitPolicyPreview {
  QuitPolicyPreview({
    required this.ruleMatched,
    required this.refundRate,
    required this.refundAmount,
    required this.penaltyAmount,
    required this.message,
  });

  final String ruleMatched;
  final num refundRate;
  final num refundAmount;
  final num penaltyAmount;
  final String message;

  factory QuitPolicyPreview.fromJson(Map<String, dynamic> json) {
    return QuitPolicyPreview(
      ruleMatched: (json['ruleMatched'] ?? '') as String,
      refundRate: (json['refundRate'] ?? 0) as num,
      refundAmount: (json['refundAmount'] ?? 0) as num,
      penaltyAmount: (json['penaltyAmount'] ?? 0) as num,
      message: (json['message'] ?? '') as String,
    );
  }
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.activityId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.messageType,
    required this.createdAt,
  });

  final int id;
  final int activityId;
  final int senderId;
  final String senderName;
  final String content;
  final String messageType;
  final String createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      activityId: json['activityId'] as int,
      senderId: json['senderId'] as int,
      senderName: (json['senderName'] ?? '') as String,
      content: (json['content'] ?? '') as String,
      messageType: (json['messageType'] ?? 'text') as String,
      createdAt: (json['createdAt'] ?? '') as String,
    );
  }
}

class ParticipantLocation {
  ParticipantLocation({
    required this.userId,
    required this.username,
    required this.latitude,
    required this.longitude,
    this.address,
    this.updatedAt,
    required this.attended,
  });

  final int userId;
  final String username;
  final double latitude;
  final double longitude;
  final String? address;
  final String? updatedAt;
  final bool attended;

  factory ParticipantLocation.fromJson(Map<String, dynamic> json) {
    return ParticipantLocation(
      userId: json['userId'] as int,
      username: (json['username'] ?? '') as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      updatedAt: json['updatedAt'] as String?,
      attended: (json['attended'] ?? false) as bool,
    );
  }
}

class ChatConversationSummary {
  ChatConversationSummary({
    required this.activityId,
    required this.activityName,
    this.lastMessageId,
    this.lastMessageContent,
    this.lastMessageTime,
    this.lastSenderId,
    this.lastSenderName,
  });

  final int activityId;
  final String activityName;
  final int? lastMessageId;
  final String? lastMessageContent;
  final String? lastMessageTime;
  final int? lastSenderId;
  final String? lastSenderName;

  factory ChatConversationSummary.fromJson(Map<String, dynamic> json) {
    return ChatConversationSummary(
      activityId: json['activityId'] as int,
      activityName: (json['activityName'] ?? '') as String,
      lastMessageId: json['lastMessageId'] as int?,
      lastMessageContent: json['lastMessageContent'] as String?,
      lastMessageTime: json['lastMessageTime'] as String?,
      lastSenderId: json['lastSenderId'] as int?,
      lastSenderName: json['lastSenderName'] as String?,
    );
  }
}
