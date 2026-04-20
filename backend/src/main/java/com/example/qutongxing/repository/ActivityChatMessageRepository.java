package com.example.qutongxing.repository;

import com.example.qutongxing.entity.ActivityChatMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ActivityChatMessageRepository extends JpaRepository<ActivityChatMessage, Long> {

    interface ConversationDigest {
        Long getActivityId();

        Long getMessageId();

        String getContent();

        java.time.LocalDateTime getCreatedAt();

        Long getSenderId();

        String getSenderName();
    }

    List<ActivityChatMessage> findTop100ByActivityIdOrderByIdDesc(Long activityId);

    List<ActivityChatMessage> findTop100ByActivityIdAndIdGreaterThanOrderByIdAsc(Long activityId, Long afterId);

    @Query(value = """
            SELECT DISTINCT ON (m.activity_id)
                m.activity_id AS activityId,
                m.id AS messageId,
                m.content AS content,
                m.created_at AS createdAt,
                m.sender_id AS senderId,
                u.username AS senderName
            FROM qtx_activity_chat_messages m
            JOIN qtx_users u ON u.id = m.sender_id
            WHERE m.activity_id IN (:activityIds)
            ORDER BY m.activity_id, m.id DESC
            """, nativeQuery = true)
    List<ConversationDigest> findLatestDigestsByActivityIds(@Param("activityIds") List<Long> activityIds);
}
