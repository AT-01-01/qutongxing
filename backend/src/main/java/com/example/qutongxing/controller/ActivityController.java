package com.example.qutongxing.controller;

import com.example.qutongxing.dto.ActivityCreateDTO;
import com.example.qutongxing.dto.ActivityResponseDTO;
import com.example.qutongxing.dto.ApiResponse;
import com.example.qutongxing.dto.ParticipantRequestDTO;
import com.example.qutongxing.entity.Activity;
import com.example.qutongxing.service.ActivityService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.net.URL;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/activities")
public class ActivityController {

    @Autowired
    private ActivityService activityService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<ActivityResponseDTO>>> getAllActivities(
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String sortOrder) {
        List<ActivityResponseDTO> activities;
        if ((keyword != null && !keyword.isEmpty()) || (sortBy != null && !sortBy.isEmpty())) {
            activities = activityService.searchAndSortActivities(userId, keyword, sortBy, sortOrder);
        } else {
            activities = activityService.getAllActivities(userId);
        }
        return ResponseEntity.ok(ApiResponse.success(activities));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ActivityResponseDTO>> getActivityById(@PathVariable Long id) {
        Activity activity = activityService.getActivityById(id);
        ActivityResponseDTO dto = convertToDTO(activity);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @GetMapping("/creator/{creatorId}")
    public ResponseEntity<ApiResponse<List<ActivityResponseDTO>>> getActivitiesByCreator(@PathVariable Long creatorId) {
        List<ActivityResponseDTO> activities = activityService.getActivitiesByCreator(creatorId);
        return ResponseEntity.ok(ApiResponse.success(activities));
    }

    @GetMapping("/participant/{userId}")
    public ResponseEntity<ApiResponse<List<ActivityResponseDTO>>> getActivitiesByParticipant(@PathVariable Long userId) {
        List<ActivityResponseDTO> activities = activityService.getActivitiesByParticipant(userId);
        return ResponseEntity.ok(ApiResponse.success(activities));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ActivityResponseDTO>> createActivity(
            @RequestParam Long userId,
            @RequestParam String name,
            @RequestParam(required = false) String description,
            @RequestParam String activityDate,
            @RequestParam BigDecimal contractAmount,
            @RequestParam(required = false) MultipartFile image,
            @RequestParam(required = false) String imageBase64,
            @RequestParam(required = false) String imageUrl,
            @RequestParam(required = false) Integer refundBeforeMinutes,
            @RequestParam(required = false) BigDecimal refundBeforeMinutesRate,
            @RequestParam(required = false) Integer refundBeforeHours,
            @RequestParam(required = false) BigDecimal refundBeforeHoursRate,
            @RequestParam(required = false) BigDecimal refundBeforeEarlyRate,
            @RequestParam(required = false) Integer lateArrivalWindowHours,
            @RequestParam(required = false) BigDecimal lateArrivalPenaltyRate,
            @RequestParam(required = false) Integer checkinDistanceMeters,
            @RequestParam(required = false) Boolean allowMemberDirectMessage) {

        ActivityCreateDTO dto = new ActivityCreateDTO();
        dto.setName(name);
        dto.setDescription(description);
        dto.setActivityDate(LocalDateTime.parse(activityDate));
        dto.setContractAmount(contractAmount);
        dto.setRefundBeforeMinutes(refundBeforeMinutes);
        dto.setRefundBeforeMinutesRate(refundBeforeMinutesRate);
        dto.setRefundBeforeHours(refundBeforeHours);
        dto.setRefundBeforeHoursRate(refundBeforeHoursRate);
        dto.setRefundBeforeEarlyRate(refundBeforeEarlyRate);
        dto.setLateArrivalWindowHours(lateArrivalWindowHours);
        dto.setLateArrivalPenaltyRate(lateArrivalPenaltyRate);
        dto.setCheckinDistanceMeters(checkinDistanceMeters);
        dto.setAllowMemberDirectMessage(allowMemberDirectMessage);

        if (image != null && !image.isEmpty()) {
            try {
                dto.setImage(image.getBytes());
            } catch (Exception e) {
                return ResponseEntity.badRequest().body(ApiResponse.error("图片上传失败"));
            }
        } else if (imageBase64 != null && !imageBase64.isEmpty()) {
            try {
                dto.setImage(java.util.Base64.getDecoder().decode(imageBase64));
            } catch (Exception e) {
                return ResponseEntity.badRequest().body(ApiResponse.error("图片Base64解码失败"));
            }
        } else if (imageUrl != null && !imageUrl.isEmpty()) {
            try {
                URL url = new URL(imageUrl);
                java.net.HttpURLConnection connection = (java.net.HttpURLConnection) url.openConnection();
                connection.setRequestProperty("User-Agent", "Mozilla/5.0");
                connection.setConnectTimeout(5000);
                connection.setReadTimeout(5000);
                if (connection.getResponseCode() == 200) {
                    java.io.InputStream inputStream = connection.getInputStream();
                    ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
                    byte[] buffer = new byte[4096];
                    int bytesRead;
                    while ((bytesRead = inputStream.read(buffer)) != -1) {
                        outputStream.write(buffer, 0, bytesRead);
                    }
                    dto.setImage(outputStream.toByteArray());
                    inputStream.close();
                } else {
                    return ResponseEntity.badRequest().body(ApiResponse.error("无法从URL下载图片，HTTP状态码: " + connection.getResponseCode()));
                }
                connection.disconnect();
            } catch (Exception e) {
                return ResponseEntity.badRequest().body(ApiResponse.error("从URL获取图片失败: " + e.getMessage()));
            }
        }

        Activity activity = activityService.createActivity(userId, dto);
        ActivityResponseDTO response = convertToDTO(activity);
        return ResponseEntity.ok(ApiResponse.success("活动创建成功", response));
    }

    @PostMapping("/{activityId}/join")
    public ResponseEntity<ApiResponse<Void>> joinActivity(
            @PathVariable Long activityId,
            @RequestParam Long userId) {
        activityService.joinActivity(userId, activityId);
        return ResponseEntity.ok(ApiResponse.success("报名成功，请等待发起人审核", null));
    }

    @PostMapping("/{activityId}/quit")
    public ResponseEntity<ApiResponse<Void>> quitActivity(
            @PathVariable Long activityId,
            @RequestParam Long userId) {
        activityService.quitActivity(userId, activityId);
        return ResponseEntity.ok(ApiResponse.success("已退出活动", null));
    }

    @PostMapping("/{activityId}/request-quit")
    public ResponseEntity<ApiResponse<Void>> requestQuitActivity(
            @PathVariable Long activityId,
            @RequestParam Long userId) {
        activityService.requestQuitActivity(userId, activityId);
        return ResponseEntity.ok(ApiResponse.success("退出申请已提交，请等待发起人审核", null));
    }

    @PostMapping("/{activityId}/approve-quit/{participantId}")
    public ResponseEntity<ApiResponse<Void>> approveQuitRequest(
            @PathVariable Long activityId,
            @PathVariable Long participantId) {
        activityService.approveQuitRequest(activityId, participantId);
        return ResponseEntity.ok(ApiResponse.success("已同意退出申请", null));
    }

    @PostMapping("/{activityId}/reject-quit/{participantId}")
    public ResponseEntity<ApiResponse<Void>> rejectQuitRequest(
            @PathVariable Long activityId,
            @PathVariable Long participantId) {
        activityService.rejectQuitRequest(activityId, participantId);
        return ResponseEntity.ok(ApiResponse.success("已拒绝退出申请", null));
    }

    @DeleteMapping("/{activityId}")
    public ResponseEntity<ApiResponse<Void>> deleteActivity(
            @PathVariable Long activityId,
            @RequestParam Long userId) {
        activityService.deleteActivity(userId, activityId);
        return ResponseEntity.ok(ApiResponse.success("活动删除成功", null));
    }

    @GetMapping("/{activityId}/participants")
    public ResponseEntity<ApiResponse<List<ParticipantRequestDTO>>> getPendingParticipants(@PathVariable Long activityId) {
        List<ParticipantRequestDTO> participants = activityService.getPendingParticipants(activityId);
        return ResponseEntity.ok(ApiResponse.success(participants));
    }

    @GetMapping("/{activityId}/approved-participants")
    public ResponseEntity<ApiResponse<List<ParticipantRequestDTO>>> getApprovedParticipants(@PathVariable Long activityId) {
        List<ParticipantRequestDTO> participants = activityService.getApprovedParticipants(activityId);
        return ResponseEntity.ok(ApiResponse.success(participants));
    }

    @PostMapping("/{activityId}/approve/{participantId}")
    public ResponseEntity<ApiResponse<Void>> approveParticipant(
            @PathVariable Long activityId,
            @PathVariable Long participantId) {
        activityService.approveParticipant(activityId, participantId);
        return ResponseEntity.ok(ApiResponse.success("已同意报名", null));
    }

    @PostMapping("/{activityId}/reject/{participantId}")
    public ResponseEntity<ApiResponse<Void>> rejectParticipant(
            @PathVariable Long activityId,
            @PathVariable Long participantId) {
        activityService.rejectParticipant(activityId, participantId);
        return ResponseEntity.ok(ApiResponse.success("已拒绝报名", null));
    }

    private ActivityResponseDTO convertToDTO(Activity activity) {
        ActivityResponseDTO dto = new ActivityResponseDTO();
        dto.setId(activity.getId());
        dto.setName(activity.getName());
        dto.setDescription(activity.getDescription());
        dto.setActivityDate(activity.getActivityDate());
        dto.setContractAmount(activity.getContractAmount());
        dto.setCreatorId(activity.getCreator().getId());
        dto.setCreatorName(activity.getCreator().getUsername());
        dto.setCreatedAt(activity.getCreatedAt());
        dto.setRefundBeforeMinutes(activity.getRefundBeforeMinutes());
        dto.setRefundBeforeMinutesRate(activity.getRefundBeforeMinutesRate());
        dto.setRefundBeforeHours(activity.getRefundBeforeHours());
        dto.setRefundBeforeHoursRate(activity.getRefundBeforeHoursRate());
        dto.setRefundBeforeEarlyRate(activity.getRefundBeforeEarlyRate());
        dto.setLateArrivalWindowHours(activity.getLateArrivalWindowHours());
        dto.setLateArrivalPenaltyRate(activity.getLateArrivalPenaltyRate());
        dto.setCheckinDistanceMeters(activity.getCheckinDistanceMeters());
        dto.setAllowMemberDirectMessage(activity.getAllowMemberDirectMessage());

        if (activity.getImage() != null && activity.getImage().length > 0) {
            dto.setImageBase64(java.util.Base64.getEncoder().encodeToString(activity.getImage()));
        }

        return dto;
    }
}
