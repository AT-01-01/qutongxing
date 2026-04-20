import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../models.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.details});
  final String message;
  final Map<String, dynamic>? details;

  @override
  String toString() => message;
}

class ApiService {
  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    _dio.interceptors.add(_buildAuthInterceptor());
  }

  static final ApiService instance = ApiService._internal();

  // 默认使用本机后端地址，便于本地联调注册/登录。
  // 若真机调试无法访问 localhost，请改成电脑局域网 IP。
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8086/api',
  );
  static const int _maxRetryCount = 3;
  Dio _dio = Dio();
  UserSession? _cachedSession;

  InterceptorsWrapper _buildAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest:
          (RequestOptions options, RequestInterceptorHandler handler) async {
            _cachedSession ??= await StorageService.readSession();
            final String? token = _cachedSession?.token;
            if (token != null && token.isNotEmpty) {
              options.headers[HttpHeaders.authorizationHeader] =
                  'Bearer $token';
            }
            handler.next(options);
          },
      onError: (DioException error, ErrorInterceptorHandler handler) async {
        final bool shouldRetry = _shouldRetry(error);
        if (shouldRetry) {
          final int currentRetry =
              (error.requestOptions.extra['retryCount'] as int?) ?? 0;
          if (currentRetry < _maxRetryCount) {
            final int nextRetry = currentRetry + 1;
            error.requestOptions.extra['retryCount'] = nextRetry;

            // 429 时尊重服务端建议的等待时间；其余网络问题按 1 秒重试。
            final int delayMs = _resolveRetryDelay(error);
            await Future<void>.delayed(Duration(milliseconds: delayMs));
            try {
              final Response<dynamic> retryResponse = await _dio.fetch<dynamic>(
                error.requestOptions,
              );
              handler.resolve(retryResponse);
              return;
            } on DioException catch (retryError) {
              handler.next(retryError);
              return;
            }
          }
        }

        if (error.response?.statusCode == 401) {
          _cachedSession = null;
          await StorageService.clearSession();
        }
        handler.next(error);
      },
    );
  }

  bool _shouldRetry(DioException error) {
    final int? statusCode = error.response?.statusCode;
    if (statusCode == 429) {
      return true;
    }
    if (statusCode != null && statusCode >= 500 && statusCode < 600) {
      return true;
    }
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  int _resolveRetryDelay(DioException error) {
    final String? retryAfter = error.response?.headers.value('retry-after');
    if (retryAfter == null) {
      return 1000;
    }
    final int? second = int.tryParse(retryAfter);
    return second == null ? 1000 : second * 1000;
  }

  ApiException _toApiException(Object error) {
    if (error is DioException) {
      final dynamic payload = error.response?.data;
      if (payload is Map<String, dynamic>) {
        final String? message = payload['message'] as String?;
        final Map<String, dynamic>? details =
            payload['data'] is Map<String, dynamic>
            ? payload['data'] as Map<String, dynamic>
            : null;
        if (message != null && message.isNotEmpty) {
          // 后端参数校验失败时会把字段错误放在 data 中，这里一并返回给页面做精准提示。
          return ApiException(message, details: details);
        }
      }
      if (error.type == DioExceptionType.connectionError) {
        return ApiException('网络连接失败，请检查网络');
      }
      return ApiException('请求失败，请稍后重试');
    }
    return ApiException('发生未知错误');
  }

  dynamic _extractData(Response<dynamic> response) {
    final dynamic payload = response.data;
    if (payload is Map<String, dynamic>) {
      return payload['data'];
    }
    return payload;
  }

  Future<UserSession> login({
    required String usernameOrPhone,
    required String password,
  }) async {
    try {
      return _loginByEndpoint('/auth/login', <String, dynamic>{
        'usernameOrPhone': usernameOrPhone,
        'password': password,
      });
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<UserSession> wechatLogin({
    required String wechatId,
    String? username,
    String? phone,
  }) async {
    try {
      return _loginByEndpoint('/auth/login/wechat', <String, dynamic>{
        'wechatId': wechatId,
        if (username != null && username.isNotEmpty) 'username': username,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<UserSession> qqLogin({
    required String qqId,
    String? username,
    String? phone,
  }) async {
    try {
      return _loginByEndpoint('/auth/login/qq', <String, dynamic>{
        'qqId': qqId,
        if (username != null && username.isNotEmpty) 'username': username,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<UserSession> smsLogin({
    required String phone,
    required String code,
  }) async {
    try {
      return _loginByEndpoint('/auth/login/sms', <String, dynamic>{
        'phone': phone,
        'code': code,
      });
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<UserSession> _loginByEndpoint(
    String path,
    Map<String, dynamic> data,
  ) async {
    final Response<dynamic> res = await _dio.post<dynamic>(path, data: data);
    final Map<String, dynamic> loginData =
        _extractData(res) as Map<String, dynamic>;
    final UserSession session = UserSession.fromLoginPayload(loginData);
    _cachedSession = session;
    await StorageService.saveSession(session);
    return session;
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/auth/register',
        data: <String, dynamic>{
          'username': username,
          'email': email,
          'password': password,
          'phone': phone,
        },
      );
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<UserProfile> getUserProfile({required int userId}) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/users/profile',
        queryParameters: <String, dynamic>{'userId': userId},
      );
      final Map<String, dynamic> data =
          (_extractData(res) as Map<String, dynamic>? ?? <String, dynamic>{});
      return UserProfile.fromJson(data);
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<UserProfile> updateUserProfile({
    required int userId,
    required String displayName,
    required String gender,
    required String bio,
    required String city,
    required String address,
  }) async {
    try {
      final Response<dynamic> res = await _dio.put<dynamic>(
        '/users/profile',
        data: <String, dynamic>{
          'userId': userId,
          'displayName': displayName,
          'gender': gender,
          'bio': bio,
          'city': city,
          'address': address,
        },
      );
      final Map<String, dynamic> data =
          (_extractData(res) as Map<String, dynamic>? ?? <String, dynamic>{});
      return UserProfile.fromJson(data);
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<void> logout() async {
    _cachedSession = null;
    await StorageService.clearSession();
  }

  Future<List<ActivityItem>> getActivities({
    int? userId,
    String? keyword,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final Map<String, dynamic> query = <String, dynamic>{};
      if (userId != null) query['userId'] = userId;
      if (keyword != null && keyword.isNotEmpty) query['keyword'] = keyword;
      if (sortBy != null && sortBy.isNotEmpty) query['sortBy'] = sortBy;
      if (sortOrder != null && sortOrder.isNotEmpty) {
        query['sortOrder'] = sortOrder;
      }

      final Response<dynamic> res = await _dio.get<dynamic>(
        '/activities',
        queryParameters: query,
      );
      final List<dynamic> list =
          (_extractData(res) as List<dynamic>? ?? <dynamic>[]);
      return list
          .map((dynamic e) => ActivityItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<List<ActivityItem>> getActivitiesByCreator(int creatorId) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/activities/creator/$creatorId',
      );
      final List<dynamic> list =
          (_extractData(res) as List<dynamic>? ?? <dynamic>[]);
      return list
          .map((dynamic e) => ActivityItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<List<ActivityItem>> getActivitiesByParticipant(int userId) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/activities/participant/$userId',
      );
      final List<dynamic> list =
          (_extractData(res) as List<dynamic>? ?? <dynamic>[]);
      return list
          .map((dynamic e) => ActivityItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<void> createActivity({
    required int userId,
    required String name,
    required String description,
    required String activityDate,
    required String contractAmount,
    String? imageUrl,
    int? refundBeforeMinutes,
    num? refundBeforeMinutesRate,
    int? refundBeforeHours,
    num? refundBeforeHoursRate,
    num? refundBeforeEarlyRate,
    int? lateArrivalWindowHours,
    num? lateArrivalPenaltyRate,
    int? checkinDistanceMeters,
    bool? allowMemberDirectMessage,
  }) async {
    try {
      final FormData data = FormData.fromMap(<String, dynamic>{
        'userId': userId,
        'name': name,
        'description': description,
        'activityDate': activityDate,
        'contractAmount': contractAmount,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        if (refundBeforeMinutes != null) 'refundBeforeMinutes': refundBeforeMinutes,
        if (refundBeforeMinutesRate != null)
          'refundBeforeMinutesRate': refundBeforeMinutesRate,
        if (refundBeforeHours != null) 'refundBeforeHours': refundBeforeHours,
        if (refundBeforeHoursRate != null)
          'refundBeforeHoursRate': refundBeforeHoursRate,
        if (refundBeforeEarlyRate != null)
          'refundBeforeEarlyRate': refundBeforeEarlyRate,
        if (lateArrivalWindowHours != null)
          'lateArrivalWindowHours': lateArrivalWindowHours,
        if (lateArrivalPenaltyRate != null)
          'lateArrivalPenaltyRate': lateArrivalPenaltyRate,
        if (checkinDistanceMeters != null)
          'checkinDistanceMeters': checkinDistanceMeters,
        if (allowMemberDirectMessage != null)
          'allowMemberDirectMessage': allowMemberDirectMessage,
      });
      await _dio.post<dynamic>(
        '/activities',
        data: data,
        options: Options(contentType: 'multipart/form-data'),
      );
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<void> joinActivity({
    required int activityId,
    required int userId,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/activities/$activityId/join',
        queryParameters: <String, dynamic>{'userId': userId},
      );
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<void> quitActivity({
    required int activityId,
    required int userId,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/activities/$activityId/quit',
        queryParameters: <String, dynamic>{'userId': userId},
      );
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<void> requestQuit({
    required int activityId,
    required int userId,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/activities/$activityId/request-quit',
        queryParameters: <String, dynamic>{'userId': userId},
      );
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<QuitPolicyPreview> getQuitPreview({
    required int activityId,
    required int userId,
  }) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/activities/$activityId/quit-preview',
        queryParameters: <String, dynamic>{'userId': userId},
      );
      final Map<String, dynamic> data =
          (_extractData(res) as Map<String, dynamic>? ?? <String, dynamic>{});
      return QuitPolicyPreview.fromJson(data);
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<QuitPolicyPreview> requestQuitWithConfirm({
    required int activityId,
    required int userId,
    required bool confirmed,
  }) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        '/activities/$activityId/request-quit-with-confirm',
        queryParameters: <String, dynamic>{
          'userId': userId,
          'confirmed': confirmed,
        },
      );
      final Map<String, dynamic> data =
          (_extractData(res) as Map<String, dynamic>? ?? <String, dynamic>{});
      return QuitPolicyPreview.fromJson(data);
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<void> deleteActivity({
    required int activityId,
    required int userId,
  }) async {
    try {
      await _dio.delete<dynamic>(
        '/activities/$activityId',
        queryParameters: <String, dynamic>{'userId': userId},
      );
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<List<ParticipantItem>> getParticipants(int activityId) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/activities/$activityId/participants',
      );
      final List<dynamic> list =
          (_extractData(res) as List<dynamic>? ?? <dynamic>[]);
      return list
          .map(
            (dynamic e) => ParticipantItem.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<List<ParticipantItem>> getApprovedParticipants(int activityId) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/activities/$activityId/approved-participants',
      );
      final List<dynamic> list =
          (_extractData(res) as List<dynamic>? ?? <dynamic>[]);
      return list
          .map(
            (dynamic e) => ParticipantItem.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<void> approveParticipant({
    required int activityId,
    required int participantId,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/activities/$activityId/approve/$participantId',
      );
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<void> rejectParticipant({
    required int activityId,
    required int participantId,
  }) async {
    try {
      await _dio.post<dynamic>('/activities/$activityId/reject/$participantId');
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<void> approveQuitRequest({
    required int activityId,
    required int participantId,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/activities/$activityId/approve-quit/$participantId',
      );
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<void> rejectQuitRequest({
    required int activityId,
    required int participantId,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/activities/$activityId/reject-quit/$participantId',
      );
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<List<ChatMessage>> getChatMessages({
    required int activityId,
    required int userId,
    int? afterId,
  }) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/activities/$activityId/chat/messages',
        queryParameters: <String, dynamic>{
          'userId': userId,
          if (afterId != null) 'afterId': afterId,
        },
      );
      final List<dynamic> list =
          (_extractData(res) as List<dynamic>? ?? <dynamic>[]);
      return list
          .map((dynamic e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<List<ChatConversationSummary>> getChatConversations({
    required int userId,
  }) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/activities/chat/conversations',
        queryParameters: <String, dynamic>{'userId': userId},
      );
      final List<dynamic> list =
          (_extractData(res) as List<dynamic>? ?? <dynamic>[]);
      return list
          .map(
            (dynamic e) =>
                ChatConversationSummary.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<ChatMessage> sendChatMessage({
    required int activityId,
    required int userId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        '/activities/$activityId/chat/messages',
        data: <String, dynamic>{
          'userId': userId,
          'content': content,
          'messageType': messageType,
        },
      );
      final Map<String, dynamic> data =
          (_extractData(res) as Map<String, dynamic>? ?? <String, dynamic>{});
      return ChatMessage.fromJson(data);
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<ParticipantLocation> shareLocation({
    required int activityId,
    required int userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        '/activities/$activityId/location/share',
        data: <String, dynamic>{
          'userId': userId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      final Map<String, dynamic> data =
          (_extractData(res) as Map<String, dynamic>? ?? <String, dynamic>{});
      return ParticipantLocation.fromJson(data);
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<List<ParticipantLocation>> getParticipantLocations({
    required int activityId,
    required int userId,
  }) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/activities/$activityId/location/participants',
        queryParameters: <String, dynamic>{'userId': userId},
      );
      final List<dynamic> list =
          (_extractData(res) as List<dynamic>? ?? <dynamic>[]);
      return list
          .map(
            (dynamic e) =>
                ParticipantLocation.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      throw _toApiException(error);
    }
  }

  Future<void> autoCheckin({
    required int activityId,
    required int userId,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/activities/$activityId/checkin/auto',
        queryParameters: <String, dynamic>{'userId': userId},
      );
    } catch (error) {
      throw _toApiException(error);
    }
  }
}
