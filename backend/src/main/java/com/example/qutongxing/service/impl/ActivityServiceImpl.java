package com.example.qutongxing.service.impl;

import com.example.qutongxing.dto.ActivityCreateDTO;
import com.example.qutongxing.dto.ActivityResponseDTO;
import com.example.qutongxing.dto.ParticipantRequestDTO;
import com.example.qutongxing.entity.Activity;
import com.example.qutongxing.entity.ActivityParticipant;
import com.example.qutongxing.entity.User;
import com.example.qutongxing.repository.ActivityParticipantRepository;
import com.example.qutongxing.repository.ActivityRepository;
import com.example.qutongxing.repository.UserRepository;
import com.example.qutongxing.service.ActivityService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.format.DateTimeFormatter;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class ActivityServiceImpl implements ActivityService {

    @Autowired
    private ActivityRepository activityRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ActivityParticipantRepository participantRepository;

    @Override
    public Activity createActivity(Long userId, ActivityCreateDTO dto) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("用户不存在"));

        Activity activity = new Activity();
        activity.setName(dto.getName());
        activity.setDescription(dto.getDescription());
        activity.setActivityDate(dto.getActivityDate());
        activity.setContractAmount(dto.getContractAmount());
        activity.setCreator(user);
        if (dto.getRefundBeforeMinutes() != null) {
            activity.setRefundBeforeMinutes(dto.getRefundBeforeMinutes());
        }
        if (dto.getRefundBeforeMinutesRate() != null) {
            activity.setRefundBeforeMinutesRate(dto.getRefundBeforeMinutesRate());
        }
        if (dto.getRefundBeforeHours() != null) {
            activity.setRefundBeforeHours(dto.getRefundBeforeHours());
        }
        if (dto.getRefundBeforeHoursRate() != null) {
            activity.setRefundBeforeHoursRate(dto.getRefundBeforeHoursRate());
        }
        if (dto.getRefundBeforeEarlyRate() != null) {
            activity.setRefundBeforeEarlyRate(dto.getRefundBeforeEarlyRate());
        }
        if (dto.getLateArrivalWindowHours() != null) {
            activity.setLateArrivalWindowHours(dto.getLateArrivalWindowHours());
        }
        if (dto.getLateArrivalPenaltyRate() != null) {
            activity.setLateArrivalPenaltyRate(dto.getLateArrivalPenaltyRate());
        }
        if (dto.getCheckinDistanceMeters() != null) {
            activity.setCheckinDistanceMeters(dto.getCheckinDistanceMeters());
        }
        if (dto.getAllowMemberDirectMessage() != null) {
            activity.setAllowMemberDirectMessage(dto.getAllowMemberDirectMessage());
        }

        if (dto.getImage() != null && dto.getImage().length > 0) {
            activity.setImage(dto.getImage());
        }

        return activityRepository.save(activity);
    }

    @Override
    public Activity getActivityById(Long id) {
        return activityRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("活动不存在"));
    }

    @Override
    public List<ActivityResponseDTO> getAllActivities(Long currentUserId) {
        List<Activity> activities = activityRepository.findAllByOrderByCreatedAtDesc();
        Map<Long, String> participantStatus = getParticipantStatusMap(currentUserId);

        return activities.stream()
                .map(activity -> convertToDTO(activity, participantStatus.get(activity.getId())))
                .collect(Collectors.toList());
    }

    @Override
    public List<ActivityResponseDTO> searchAndSortActivities(Long currentUserId, String keyword, String sortBy, String sortOrder) {
        List<Activity> activities;

        if (keyword != null && !keyword.trim().isEmpty()) {
            activities = activityRepository.searchByKeyword(keyword.trim());
        } else {
            activities = activityRepository.findAll();
        }

        if (sortBy != null && !sortBy.isEmpty()) {
            switch (sortBy) {
                case "contractAmount":
                    activities = "desc".equalsIgnoreCase(sortOrder)
                            ? activityRepository.findAllByOrderByContractAmountDesc()
                            : activityRepository.findAllByOrderByContractAmountAsc();
                    if (keyword != null && !keyword.trim().isEmpty()) {
                        activities = activities.stream()
                                .filter(a -> a.getName().toLowerCase().contains(keyword.toLowerCase())
                                        || (a.getDescription() != null && a.getDescription().toLowerCase().contains(keyword.toLowerCase())))
                                .collect(Collectors.toList());
                    }
                    break;
                case "activityDate":
                    activities = "desc".equalsIgnoreCase(sortOrder)
                            ? activityRepository.findAllByOrderByActivityDateDesc()
                            : activityRepository.findAllByOrderByActivityDateAsc();
                    if (keyword != null && !keyword.trim().isEmpty()) {
                        activities = activities.stream()
                                .filter(a -> a.getName().toLowerCase().contains(keyword.toLowerCase())
                                        || (a.getDescription() != null && a.getDescription().toLowerCase().contains(keyword.toLowerCase())))
                                .collect(Collectors.toList());
                    }
                    break;
                case "participantCount":
                    activities = activityRepository.findAllByOrderByParticipantCountDesc();
                    if (keyword != null && !keyword.trim().isEmpty()) {
                        activities = activities.stream()
                                .filter(a -> a.getName().toLowerCase().contains(keyword.toLowerCase())
                                        || (a.getDescription() != null && a.getDescription().toLowerCase().contains(keyword.toLowerCase())))
                                .collect(Collectors.toList());
                    }
                    break;
                default:
                    break;
            }
        }

        Map<Long, String> participantStatus = getParticipantStatusMap(currentUserId);
        return activities.stream()
                .map(activity -> convertToDTO(activity, participantStatus.get(activity.getId())))
                .collect(Collectors.toList());
    }

    @Override
    public List<ActivityResponseDTO> getActivitiesByCreator(Long creatorId) {
        return activityRepository.findByCreatorId(creatorId)
                .stream()
                .map(activity -> convertToDTO(activity, null))
                .collect(Collectors.toList());
    }

    @Override
    public List<ActivityResponseDTO> getActivitiesByParticipant(Long userId) {
        return participantRepository.findByUserId(userId)
                .stream()
                .filter(p -> "approved".equals(p.getStatus()))
                .map(p -> convertToDTO(p.getActivity(), "approved"))
                .collect(Collectors.toList());
    }

    @Override
    public void joinActivity(Long userId, Long activityId) {
        if (participantRepository.existsByUserIdAndActivityId(userId, activityId)) {
            throw new RuntimeException("您已参加此活动");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("用户不存在"));
        Activity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new RuntimeException("活动不存在"));
        if (activity.getCreator().getId().equals(userId)) {
            throw new RuntimeException("不能报名自己创建的活动");
        }

        ActivityParticipant participant = new ActivityParticipant();
        participant.setUser(user);
        participant.setActivity(activity);
        participant.setAttended(false);
        participant.setStatus("pending");

        participantRepository.save(participant);
    }

    @Override
    public void deleteActivity(Long userId, Long activityId) {
        Activity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new RuntimeException("活动不存在"));

        if (!activity.getCreator().getId().equals(userId)) {
            throw new RuntimeException("无权删除此活动");
        }

        Long approvedCount = participantRepository.countByActivityIdAndStatus(activityId, "approved");
        if (approvedCount != null && approvedCount > 0) {
            throw new RuntimeException("已有报名成功的用户，无法删除活动");
        }

        participantRepository.deleteByActivityId(activityId);
        activityRepository.delete(activity);
    }

    @Override
    public List<ParticipantRequestDTO> getPendingParticipants(Long activityId) {
        Activity activity = activityRepository.findById(activityId)
                .orElseThrow(() -> new RuntimeException("活动不存在"));

        return participantRepository.findByActivityId(activityId)
                .stream()
                .filter(p -> "pending".equals(p.getStatus()) ||
                            ("approved".equals(p.getStatus()) && Boolean.TRUE.equals(p.getQuitRequested())))
                .map(this::convertToParticipantDTO)
                .collect(Collectors.toList());
    }

    @Override
    public List<ParticipantRequestDTO> getApprovedParticipants(Long activityId) {
        return participantRepository.findByActivityId(activityId)
                .stream()
                .filter(p -> "approved".equals(p.getStatus()) && !Boolean.TRUE.equals(p.getQuitRequested()))
                .map(this::convertToParticipantDTO)
                .collect(Collectors.toList());
    }

    @Override
    public void approveParticipant(Long activityId, Long participantId) {
        ActivityParticipant participant = participantRepository.findById(participantId)
                .orElseThrow(() -> new RuntimeException("报名记录不存在"));

        if (!participant.getActivity().getId().equals(activityId)) {
            throw new RuntimeException("活动ID不匹配");
        }

        participant.setStatus("approved");
        participantRepository.save(participant);
    }

    @Override
    public void rejectParticipant(Long activityId, Long participantId) {
        ActivityParticipant participant = participantRepository.findById(participantId)
                .orElseThrow(() -> new RuntimeException("报名记录不存在"));

        if (!participant.getActivity().getId().equals(activityId)) {
            throw new RuntimeException("活动ID不匹配");
        }

        participant.setStatus("rejected");
        participantRepository.save(participant);
    }

    @Override
    public void quitActivity(Long userId, Long activityId) {
        ActivityParticipant participant = participantRepository.findByUserIdAndActivityId(userId, activityId)
                .orElseThrow(() -> new RuntimeException("您没有报名此活动"));

        if ("pending".equals(participant.getStatus()) || "rejected".equals(participant.getStatus())) {
            participantRepository.delete(participant);
            return;
        }

        throw new RuntimeException("已报名成功的活动无法直接退出，请申请退出");
    }

    @Override
    public void requestQuitActivity(Long userId, Long activityId) {
        ActivityParticipant participant = participantRepository.findByUserIdAndActivityId(userId, activityId)
                .orElseThrow(() -> new RuntimeException("您没有报名此活动"));

        if (!"approved".equals(participant.getStatus())) {
            throw new RuntimeException("只有报名成功的用户才能申请退出");
        }

        if (Boolean.TRUE.equals(participant.getQuitRequested())) {
            throw new RuntimeException("您已经提交过退出申请，请等待发起人审核");
        }

        participant.setQuitRequested(true);
        participantRepository.save(participant);
    }

    @Override
    public void approveQuitRequest(Long activityId, Long participantId) {
        ActivityParticipant participant = participantRepository.findById(participantId)
                .orElseThrow(() -> new RuntimeException("报名记录不存在"));

        if (!participant.getActivity().getId().equals(activityId)) {
            throw new RuntimeException("活动ID不匹配");
        }

        if (!Boolean.TRUE.equals(participant.getQuitRequested())) {
            throw new RuntimeException("该用户没有申请退出");
        }

        participantRepository.delete(participant);
    }

    @Override
    public void rejectQuitRequest(Long activityId, Long participantId) {
        ActivityParticipant participant = participantRepository.findById(participantId)
                .orElseThrow(() -> new RuntimeException("报名记录不存在"));

        if (!participant.getActivity().getId().equals(activityId)) {
            throw new RuntimeException("活动ID不匹配");
        }

        if (!Boolean.TRUE.equals(participant.getQuitRequested())) {
            throw new RuntimeException("该用户没有申请退出");
        }

        participant.setQuitRequested(false);
        participantRepository.save(participant);
    }

    private Map<Long, String> getParticipantStatusMap(Long userId) {
        if (userId == null) {
            return Map.of();
        }
        return participantRepository.findByUserId(userId).stream()
                .collect(Collectors.toMap(
                        p -> p.getActivity().getId(),
                        p -> p.getStatus(),
                        (existing, replacement) -> existing
                ));
    }

    private ActivityResponseDTO convertToDTO(Activity activity, String joinStatus) {
        ActivityResponseDTO dto = new ActivityResponseDTO();
        dto.setId(activity.getId());
        dto.setName(activity.getName());
        dto.setDescription(activity.getDescription());
        dto.setActivityDate(activity.getActivityDate());
        dto.setContractAmount(activity.getContractAmount());
        dto.setCreatorId(activity.getCreator().getId());
        dto.setCreatorName(activity.getCreator().getUsername());
        dto.setCreatedAt(activity.getCreatedAt());
        dto.setJoinStatus(joinStatus);
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
            dto.setImageBase64(Base64.getEncoder().encodeToString(activity.getImage()));
        }

        dto.setPendingCount(participantRepository.countByActivityIdAndStatus(activity.getId(), "pending").intValue());
        dto.setQuitRequestedCount(participantRepository.countByActivityIdAndQuitRequestedTrue(activity.getId()).intValue());
        dto.setApprovedCount(participantRepository.countByActivityIdAndStatusApproved(activity.getId()).intValue());

        return dto;
    }

    private ParticipantRequestDTO convertToParticipantDTO(ActivityParticipant participant) {
        ParticipantRequestDTO dto = new ParticipantRequestDTO();
        dto.setId(participant.getId());
        dto.setUserId(participant.getUser().getId());
        dto.setUsername(participant.getUser().getUsername());
        dto.setEmail(participant.getUser().getEmail());
        dto.setPhone(participant.getUser().getPhone());
        dto.setActivityId(participant.getActivity().getId());
        dto.setActivityName(participant.getActivity().getName());
        dto.setStatus(participant.getStatus());
        dto.setQuitRequested(participant.getQuitRequested());
        dto.setJoinedAt(participant.getJoinedAt().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        return dto;
    }
}
