package com.example.qutongxing.service;

import com.example.qutongxing.dto.ActivityCreateDTO;
import com.example.qutongxing.dto.ActivityResponseDTO;
import com.example.qutongxing.dto.ParticipantRequestDTO;
import com.example.qutongxing.entity.Activity;

import java.util.List;

public interface ActivityService {

    Activity createActivity(Long userId, ActivityCreateDTO dto);

    Activity getActivityById(Long id);

    List<ActivityResponseDTO> getAllActivities(Long currentUserId);

    List<ActivityResponseDTO> getActivitiesByCreator(Long creatorId);

    List<ActivityResponseDTO> getActivitiesByParticipant(Long userId);

    List<ActivityResponseDTO> searchAndSortActivities(Long currentUserId, String keyword, String sortBy, String sortOrder);

    void joinActivity(Long userId, Long activityId);

    void deleteActivity(Long userId, Long activityId);

    List<ParticipantRequestDTO> getPendingParticipants(Long activityId);

    List<ParticipantRequestDTO> getApprovedParticipants(Long activityId);

    void approveParticipant(Long activityId, Long participantId);

    void rejectParticipant(Long activityId, Long participantId);

    void quitActivity(Long userId, Long activityId);

    void requestQuitActivity(Long userId, Long activityId);

    void approveQuitRequest(Long activityId, Long participantId);

    void rejectQuitRequest(Long activityId, Long participantId);
}