package com.example.qutongxing.controller;

import com.example.qutongxing.dto.*;
import com.example.qutongxing.entity.Activity;
import com.example.qutongxing.entity.ActivityChatMessage;
import com.example.qutongxing.entity.ActivityParticipant;
import com.example.qutongxing.entity.User;
import com.example.qutongxing.repository.ActivityChatMessageRepository;
import com.example.qutongxing.repository.ActivityParticipantRepository;
import com.example.qutongxing.repository.ActivityRepository;
import com.example.qutongxing.repository.UserRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.InputStream;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/activities")
public class ActivityAdvancedController {

    private final ActivityRepository activityRepository;
    private final ActivityParticipantRepository participantRepository;
    private final ActivityChatMessageRepository chatMessageRepository;
    private final UserRepository userRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${amap.web-key:}")
    private String amapWebKey;

    public ActivityAdvancedController(
            ActivityRepository activityRepository,
            ActivityParticipantRepository participantRepository,
            ActivityChatMessageRepository chatMessageRepository,
            UserRepository userRepository
    ) {
        this.activityRepository = activityRepository;
        this.participantRepository = participantRepository;
        this.chatMessageRepository = chatMessageRepository;
        this.userRepository = userRepository;
    }

    @GetMapping("/{activityId}/quit-preview")
    public ResponseEntity<ApiResponse<QuitPolicyPreviewDTO>> previewQuit(
            @PathVariable Long activityId,
            @RequestParam Long userId
    ) {
        ActivityParticipant participant = findParticipant(userId, activityId);
        if (!"approved".equals(participant.getStatus())) {
            throw new RuntimeException("仅报名成功成员可申请退出");
        }
        QuitPolicyPreviewDTO preview = buildQuitPreview(participant);
        return ResponseEntity.ok(ApiResponse.success(preview));
    }

    @PostMapping("/{activityId}/request-quit-with-confirm")
    public ResponseEntity<ApiResponse<QuitPolicyPreviewDTO>> requestQuitWithConfirm(
            @PathVariable Long activityId,
            @RequestParam Long userId,
            @RequestParam(defaultValue = "false") boolean confirmed
    ) {
        ActivityParticipant participant = findParticipant(userId, activityId);
        if (!"approved".equals(participant.getStatus())) {
            throw new RuntimeException("只有报名成功的用户才能申请退出");
        }
        if (Boolean.TRUE.equals(participant.getQuitRequested())) {
            throw new RuntimeException("您已经提交过退出申请");
        }
        QuitPolicyPreviewDTO preview = buildQuitPreview(participant);
        if (!confirmed) {
            preview.setMessage(preview.getMessage() + "（尚未确认）");
            return ResponseEntity.ok(ApiResponse.success("请二次确认退出规则", preview));
        }
        participant.setQuitRequested(true);
        participantRepository.save(participant);
        return ResponseEntity.ok(ApiResponse.success("退出申请已提交", preview));
    }

    @PostMapping("/{activityId}/location/share")
    public ResponseEntity<ApiResponse<ParticipantLocationDTO>> shareLocation(
            @PathVariable Long activityId,
            @RequestBody LocationShareDTO request
    ) {
        if (request.getUserId() == null || request.getLatitude() == null || request.getLongitude() == null) {
            throw new RuntimeException("位置参数不完整");
        }
        ActivityParticipant participant = findParticipant(request.getUserId(), activityId);
        if (!"approved".equals(participant.getStatus())) {
            throw new RuntimeException("仅报名成功成员可共享位置");
        }

        participant.setLastLatitude(request.getLatitude());
        participant.setLastLongitude(request.getLongitude());
        participant.setLastLocationAt(LocalDateTime.now());
        participant.setLastLocationAddress(resolveAddressByAmap(request.getLongitude(), request.getLatitude()));
        participantRepository.save(participant);

        ParticipantLocationDTO dto = toLocationDTO(participant);
        return ResponseEntity.ok(ApiResponse.success("位置共享成功", dto));
    }

    @GetMapping("/{activityId}/location/participants")
    public ResponseEntity<ApiResponse<List<ParticipantLocationDTO>>> getParticipantLocations(
            @PathVariable Long activityId,
            @RequestParam Long userId
    ) {
        ensureGroupMember(userId, activityId);
        List<ParticipantLocationDTO> locations = participantRepository
                .findByActivityIdAndStatus(activityId, "approved")
                .stream()
                .filter(p -> p.getLastLatitude() != null && p.getLastLongitude() != null)
                .map(this::toLocationDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success(locations));
    }

    @PostMapping("/{activityId}/checkin/auto")
    public ResponseEntity<ApiResponse<String>> autoCheckin(
            @PathVariable Long activityId,
            @RequestParam Long userId
    ) {
        ActivityParticipant me = findParticipant(userId, activityId);
        if (!"approved".equals(me.getStatus())) {
            throw new RuntimeException("仅报名成功成员可打卡");
        }
        if (me.getLastLatitude() == null || me.getLastLongitude() == null) {
            throw new RuntimeException("请先共享当前位置");
        }
        Activity activity = me.getActivity();
        List<ActivityParticipant> peers = participantRepository.findByActivityIdAndStatusAndUserIdNot(
                activityId,
                "approved",
                userId
        );
        boolean nearAnyPeer = peers.stream()
                .filter(p -> p.getLastLatitude() != null && p.getLastLongitude() != null)
                .anyMatch(p ->
                        distanceMeters(
                                me.getLastLatitude(),
                                me.getLastLongitude(),
                                p.getLastLatitude(),
                                p.getLastLongitude()
                        ) <= activity.getCheckinDistanceMeters()
                );

        if (!nearAnyPeer) {
            return ResponseEntity.ok(ApiResponse.error(
                    "未检测到附近团员，保持共享位置后重试（阈值 " + activity.getCheckinDistanceMeters() + "m）"
            ));
        }
        me.setAttended(true);
        me.setArrivedAt(LocalDateTime.now());
        participantRepository.save(me);
        return ResponseEntity.ok(ApiResponse.success("打卡成功，已记录到达时间", null));
    }

    @GetMapping("/{activityId}/chat/messages")
    public ResponseEntity<ApiResponse<List<ChatMessageDTO>>> listChatMessages(
            @PathVariable Long activityId,
            @RequestParam Long userId,
            @RequestParam(required = false) Long afterId
    ) {
        ensureGroupMember(userId, activityId);
        List<ActivityChatMessage> messages = afterId == null
                ? chatMessageRepository.findTop100ByActivityIdOrderByIdDesc(activityId)
                : chatMessageRepository.findTop100ByActivityIdAndIdGreaterThanOrderByIdAsc(activityId, afterId);
        List<ChatMessageDTO> result;
        if (afterId == null) {
            List<ActivityChatMessage> ordered = new ArrayList<>(messages);
            ordered.sort(Comparator.comparing(ActivityChatMessage::getId));
            result = ordered.stream().map(this::toChatMessageDTO).collect(Collectors.toList());
        } else {
            result = messages.stream().map(this::toChatMessageDTO).collect(Collectors.toList());
        }
        return ResponseEntity.ok(ApiResponse.success(result));
    }

    @GetMapping("/chat/conversations")
    public ResponseEntity<ApiResponse<List<ChatConversationDTO>>> listConversations(
            @RequestParam Long userId
    ) {
        userRepository.findById(userId).orElseThrow(() -> new RuntimeException("用户不存在"));
        List<Activity> createdActivities = activityRepository.findByCreatorId(userId);
        List<Long> approvedJoinedActivityIds = participantRepository.findApprovedActivityIdsByUserId(userId);

        Map<Long, Activity> activityMap = new LinkedHashMap<>();
        for (Activity activity : createdActivities) {
            activityMap.put(activity.getId(), activity);
        }
        if (!approvedJoinedActivityIds.isEmpty()) {
            for (Activity activity : activityRepository.findAllById(approvedJoinedActivityIds)) {
                activityMap.putIfAbsent(activity.getId(), activity);
            }
        }
        if (activityMap.isEmpty()) {
            return ResponseEntity.ok(ApiResponse.success(new ArrayList<>()));
        }

        List<Long> activityIds = new ArrayList<>(activityMap.keySet());
        List<ActivityChatMessageRepository.ConversationDigest> digests =
                chatMessageRepository.findLatestDigestsByActivityIds(activityIds);
        Map<Long, ActivityChatMessageRepository.ConversationDigest> digestByActivity = new LinkedHashMap<>();
        for (ActivityChatMessageRepository.ConversationDigest digest : digests) {
            digestByActivity.put(digest.getActivityId(), digest);
        }

        List<ChatConversationDTO> result = new ArrayList<>();
        for (Long activityId : activityIds) {
            Activity activity = activityMap.get(activityId);
            ChatConversationDTO dto = new ChatConversationDTO();
            dto.setActivityId(activityId);
            dto.setActivityName(activity == null ? "" : activity.getName());
            ActivityChatMessageRepository.ConversationDigest digest = digestByActivity.get(activityId);
            if (digest != null) {
                dto.setLastMessageId(digest.getMessageId());
                dto.setLastMessageContent(digest.getContent());
                dto.setLastMessageTime(digest.getCreatedAt());
                dto.setLastSenderId(digest.getSenderId());
                dto.setLastSenderName(digest.getSenderName());
            }
            result.add(dto);
        }
        result.sort((a, b) -> {
            Long aId = a.getLastMessageId();
            Long bId = b.getLastMessageId();
            if (aId == null && bId == null) {
                return 0;
            }
            if (aId == null) {
                return 1;
            }
            if (bId == null) {
                return -1;
            }
            return Long.compare(bId, aId);
        });
        return ResponseEntity.ok(ApiResponse.success(result));
    }

    @PostMapping("/{activityId}/chat/messages")
    public ResponseEntity<ApiResponse<ChatMessageDTO>> sendChatMessage(
            @PathVariable Long activityId,
            @RequestBody SendChatMessageDTO request
    ) {
        ensureGroupMember(request.getUserId(), activityId);
        Activity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new RuntimeException("活动不存在"));
        User sender = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new RuntimeException("用户不存在"));

        ActivityChatMessage message = new ActivityChatMessage();
        message.setActivity(activity);
        message.setSender(sender);
        message.setContent(request.getContent().trim());
        message.setMessageType(
                request.getMessageType() == null || request.getMessageType().isBlank()
                        ? "text"
                        : request.getMessageType().trim()
        );
        chatMessageRepository.save(message);
        return ResponseEntity.ok(ApiResponse.success(toChatMessageDTO(message)));
    }

    @GetMapping("/{activityId}/chat/contacts")
    public ResponseEntity<ApiResponse<List<ParticipantRequestDTO>>> listContacts(
            @PathVariable Long activityId,
            @RequestParam Long userId
    ) {
        Activity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new RuntimeException("活动不存在"));
        ensureGroupMember(userId, activityId);
        if (!Boolean.TRUE.equals(activity.getAllowMemberDirectMessage())
                && !activity.getCreator().getId().equals(userId)) {
            throw new RuntimeException("团长已关闭团员互相私信");
        }
        List<ParticipantRequestDTO> contacts = participantRepository.findByActivityIdAndStatus(activityId, "approved")
                .stream()
                .map(this::toParticipantDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success(contacts));
    }

    @PostMapping("/{activityId}/chat/direct-message-setting")
    public ResponseEntity<ApiResponse<Boolean>> updateDirectMessageSetting(
            @PathVariable Long activityId,
            @RequestParam Long userId,
            @RequestParam boolean enabled
    ) {
        Activity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new RuntimeException("活动不存在"));
        if (!activity.getCreator().getId().equals(userId)) {
            throw new RuntimeException("仅团长可设置团员私信权限");
        }
        activity.setAllowMemberDirectMessage(enabled);
        activityRepository.save(activity);
        return ResponseEntity.ok(ApiResponse.success("设置已更新", enabled));
    }

    private ActivityParticipant findParticipant(Long userId, Long activityId) {
        return participantRepository.findByUserIdAndActivityId(userId, activityId)
                .orElseThrow(() -> new RuntimeException("未找到活动成员记录"));
    }

    private void ensureGroupMember(Long userId, Long activityId) {
        Activity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new RuntimeException("活动不存在"));
        if (activity.getCreator().getId().equals(userId)) {
            return;
        }
        ActivityParticipant participant = participantRepository.findByUserIdAndActivityId(userId, activityId)
                .orElseThrow(() -> new RuntimeException("仅活动成员可访问"));
        if (!"approved".equals(participant.getStatus())) {
            throw new RuntimeException("仅报名成功成员可访问");
        }
    }

    private QuitPolicyPreviewDTO buildQuitPreview(ActivityParticipant participant) {
        Activity activity = participant.getActivity();
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime start = activity.getActivityDate();
        BigDecimal amount = activity.getContractAmount();

        BigDecimal rate;
        String rule;
        String message;

        if (now.isBefore(start.minusHours(activity.getRefundBeforeHours()))) {
            rate = safeRate(activity.getRefundBeforeEarlyRate(), BigDecimal.ONE);
            rule = "before_three_hours_earlier";
            message = "活动前" + activity.getRefundBeforeHours() + "小时以前申请，返还" + percentText(rate) + "积分";
        } else if (now.isBefore(start.minusMinutes(activity.getRefundBeforeMinutes()))) {
            rate = safeRate(activity.getRefundBeforeHoursRate(), new BigDecimal("0.80"));
            rule = "before_ten_minutes_to_three_hours";
            message = "活动前" + activity.getRefundBeforeMinutes() + "分钟到前" + activity.getRefundBeforeHours()
                    + "小时申请，返还" + percentText(rate) + "积分";
        } else if (now.isBefore(start)) {
            rate = safeRate(activity.getRefundBeforeMinutesRate(), new BigDecimal("0.50"));
            rule = "start_to_before_ten_minutes";
            message = "活动开始到开始前" + activity.getRefundBeforeMinutes()
                    + "分钟申请，返还" + percentText(rate) + "积分";
        } else {
            LocalDateTime graceEnd = start.plusHours(activity.getLateArrivalWindowHours());
            if (Boolean.TRUE.equals(participant.getAttended())
                    && participant.getArrivedAt() != null
                    && !participant.getArrivedAt().isAfter(graceEnd)) {
                BigDecimal penaltyRate = safeRate(activity.getLateArrivalPenaltyRate(), new BigDecimal("0.20"));
                rate = BigDecimal.ONE.subtract(penaltyRate);
                rule = "arrived_within_window";
                message = "活动开始后" + activity.getLateArrivalWindowHours()
                        + "小时内到达，扣除" + percentText(penaltyRate) + "积分";
            } else {
                rate = BigDecimal.ZERO;
                rule = "no_show_after_start";
                long waitHours = Duration.between(start, now).toHours();
                message = "活动开始后已等待" + Math.max(waitHours, 0) + "小时，未满足返还条件，不返还积分";
            }
        }

        QuitPolicyPreviewDTO dto = new QuitPolicyPreviewDTO();
        dto.setActivityId(activity.getId());
        dto.setUserId(participant.getUser().getId());
        dto.setRuleMatched(rule);
        dto.setRefundRate(rate);
        dto.setRefundAmount(amount.multiply(rate).setScale(2, RoundingMode.HALF_UP));
        dto.setPenaltyAmount(amount.subtract(dto.getRefundAmount()).setScale(2, RoundingMode.HALF_UP));
        dto.setMessage(message);
        return dto;
    }

    private BigDecimal safeRate(BigDecimal rate, BigDecimal fallback) {
        if (rate == null) {
            return fallback;
        }
        if (rate.compareTo(BigDecimal.ZERO) < 0) {
            return BigDecimal.ZERO;
        }
        if (rate.compareTo(BigDecimal.ONE) > 0) {
            return BigDecimal.ONE;
        }
        return rate;
    }

    private String percentText(BigDecimal rate) {
        return rate.multiply(new BigDecimal("100")).stripTrailingZeros().toPlainString() + "%";
    }

    private String resolveAddressByAmap(Double longitude, Double latitude) {
        if (amapWebKey == null || amapWebKey.isBlank()) {
            return null;
        }
        try {
            String location = longitude + "," + latitude;
            String url = "https://restapi.amap.com/v3/geocode/regeo?output=json&location="
                    + location + "&key=" + amapWebKey;
            HttpURLConnection connection = (HttpURLConnection) new URL(url).openConnection();
            connection.setRequestMethod("GET");
            connection.setConnectTimeout(5000);
            connection.setReadTimeout(5000);
            if (connection.getResponseCode() != 200) {
                return null;
            }
            InputStream stream = connection.getInputStream();
            String body = new String(stream.readAllBytes(), StandardCharsets.UTF_8);
            stream.close();
            JsonNode root = objectMapper.readTree(body);
            if (!"1".equals(root.path("status").asText())) {
                return null;
            }
            return root.path("regeocode").path("formatted_address").asText(null);
        } catch (Exception ignored) {
            return null;
        }
    }

    private double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
        final double earthRadius = 6371000.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return earthRadius * c;
    }

    private ParticipantLocationDTO toLocationDTO(ActivityParticipant participant) {
        ParticipantLocationDTO dto = new ParticipantLocationDTO();
        dto.setUserId(participant.getUser().getId());
        dto.setUsername(participant.getUser().getUsername());
        dto.setLatitude(participant.getLastLatitude());
        dto.setLongitude(participant.getLastLongitude());
        dto.setAddress(participant.getLastLocationAddress());
        dto.setUpdatedAt(participant.getLastLocationAt());
        dto.setAttended(participant.getAttended());
        return dto;
    }

    private ChatMessageDTO toChatMessageDTO(ActivityChatMessage message) {
        ChatMessageDTO dto = new ChatMessageDTO();
        dto.setId(message.getId());
        dto.setActivityId(message.getActivity().getId());
        dto.setSenderId(message.getSender().getId());
        dto.setSenderName(message.getSender().getUsername());
        dto.setContent(message.getContent());
        dto.setMessageType(message.getMessageType());
        dto.setCreatedAt(message.getCreatedAt());
        return dto;
    }

    private ParticipantRequestDTO toParticipantDTO(ActivityParticipant participant) {
        ParticipantRequestDTO dto = new ParticipantRequestDTO();
        dto.setId(participant.getId());
        dto.setUserId(participant.getUser().getId());
        dto.setUsername(participant.getUser().getUsername());
        dto.setEmail(participant.getUser().getEmail());
        dto.setPhone(participant.getUser().getPhone());
        dto.setGender(participant.getUser().getGender());
        dto.setRealNameVerified(Boolean.TRUE.equals(participant.getUser().getRealNameVerified()));
        dto.setActivityId(participant.getActivity().getId());
        dto.setActivityName(participant.getActivity().getName());
        dto.setStatus(participant.getStatus());
        dto.setQuitRequested(participant.getQuitRequested());
        dto.setJoinedAt(participant.getJoinedAt() == null ? null : participant.getJoinedAt().toString());
        return dto;
    }
}
