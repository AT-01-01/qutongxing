import { useState, useEffect } from 'react';
import { View, Text, FlatList, Image, TouchableOpacity, StyleSheet, Alert, ActivityIndicator, Modal, SafeAreaView, StatusBar } from 'react-native';
import { activityAPI } from '../services/api';
import { storage } from '../utils/storage';

export default function ActivityManagementScreen({ navigation }) {
  const [createdActivities, setCreatedActivities] = useState([]);
  const [joinedActivities, setJoinedActivities] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedActivity, setSelectedActivity] = useState(null);
  const [participants, setParticipants] = useState([]);
  const [showParticipantsModal, setShowParticipantsModal] = useState(false);
  const [showApprovedModal, setShowApprovedModal] = useState(false);
  const [approvedParticipants, setApprovedParticipants] = useState([]);
  const [loadingParticipants, setLoadingParticipants] = useState(false);

  useEffect(() => {
    fetchActivities();
  }, []);

  const fetchActivities = async () => {
    setLoading(true);
    const user = await storage.getUser();
    if (!user) {
      setLoading(false);
      return;
    }

    try {
      const [createdRes, joinedRes] = await Promise.all([
        activityAPI.getByCreator(user.userId),
        activityAPI.getByParticipant(user.userId),
      ]);
      setCreatedActivities(createdRes.data.data || []);
      setJoinedActivities(joinedRes.data.data || []);
    } catch (error) {
      console.error('Failed to fetch activities:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchParticipants = async (activity) => {
    setSelectedActivity(activity);
    setShowParticipantsModal(true);
    setLoadingParticipants(true);

    try {
      const response = await activityAPI.getParticipants(activity.id);
      setParticipants(response.data.data || []);
    } catch (error) {
      console.error('Failed to fetch participants:', error);
      Alert.alert('错误', '获取报名列表失败');
    } finally {
      setLoadingParticipants(false);
    }
  };

  const showApprovedList = async (activity) => {
    if (!activity.approvedCount) return;
    setSelectedActivity(activity);
    setShowApprovedModal(true);
    setLoadingParticipants(true);

    try {
      const response = await activityAPI.getApprovedParticipants(activity.id);
      console.log('API response:', JSON.stringify(response.data.data));
      const approved = response.data.data || [];
      console.log('Approved participants:', approved.length);
      setApprovedParticipants(approved);
    } catch (error) {
      console.error('Failed to fetch approved participants:', error);
      Alert.alert('错误', '获取参加列表失败');
    } finally {
      setLoadingParticipants(false);
    }
  };

  const handleApprove = async (participantId) => {
    try {
      await activityAPI.approveParticipant(selectedActivity.id, participantId);
      Alert.alert('成功', '已同意报名');
      fetchParticipants(selectedActivity);
      fetchActivities();
    } catch (error) {
      Alert.alert('错误', error.response?.data?.message || '操作失败');
    }
  };

  const handleReject = async (participantId) => {
    try {
      await activityAPI.rejectParticipant(selectedActivity.id, participantId);
      Alert.alert('成功', '已拒绝报名');
      fetchParticipants(selectedActivity);
      fetchActivities();
    } catch (error) {
      Alert.alert('错误', error.response?.data?.message || '操作失败');
    }
  };

  const handleApproveQuitRequest = async (participantId) => {
    try {
      await activityAPI.approveQuitRequest(selectedActivity.id, participantId);
      Alert.alert('成功', '已同意退出申请');
      fetchParticipants(selectedActivity);
      fetchActivities();
    } catch (error) {
      Alert.alert('错误', error.response?.data?.message || '操作失败');
    }
  };

  const handleRejectQuitRequest = async (participantId) => {
    try {
      await activityAPI.rejectQuitRequest(selectedActivity.id, participantId);
      Alert.alert('成功', '已拒绝退出申请');
      fetchParticipants(selectedActivity);
      fetchActivities();
    } catch (error) {
      Alert.alert('错误', error.response?.data?.message || '操作失败');
    }
  };

  const handleDeleteActivity = async (activityId) => {
    const user = await storage.getUser();
    if (!user) return;

    Alert.alert(
      '确认删除',
      '确定要删除这个活动吗？此操作不可恢复',
      [
        { text: '取消', style: 'cancel' },
        {
          text: '删除',
          style: 'destructive',
          onPress: async () => {
            try {
              await activityAPI.delete(activityId, user.userId);
              Alert.alert('成功', '删除成功');
              fetchActivities();
            } catch (error) {
              Alert.alert('错误', error.response?.data?.message || '删除失败');
            }
          },
        },
      ]
    );
  };

  const renderCreatedActivity = ({ item }) => (
    <View style={styles.card}>
      <View style={styles.cardImageContainer}>
        {item.imageBase64 ? (
          <Image source={{ uri: `data:image/jpeg;base64,${item.imageBase64}` }} style={styles.cardImage} />
        ) : (
          <View style={styles.placeholderImage}>
            <Text style={styles.placeholderIcon}>🏕️</Text>
          </View>
        )}
      </View>

      <View style={styles.cardContent}>
        <View style={styles.titleRow}>
          <Text style={styles.activityName} numberOfLines={1}>{item.name}</Text>
          <View style={styles.statusTagsContainer}>
            <TouchableOpacity style={styles.statusTagTouchable} onPress={() => showApprovedList(item)}>
              <Text style={styles.statusTagText}>已:{item.approvedCount || 0}</Text>
            </TouchableOpacity>
          </View>
        </View>
        <Text style={styles.activityDescription} numberOfLines={2}>{item.description}</Text>

        <View style={styles.metaRow}>
          <View style={styles.metaItem}>
            <Text style={styles.metaIcon}>💰</Text>
            <Text style={styles.contractAmountText}>¥{item.contractAmount || 0}</Text>
          </View>
          <View style={styles.metaItem}>
            <Text style={styles.metaIcon}>📅</Text>
            <Text style={styles.metaText}>{item.activityDate ? item.activityDate.split('T')[0] : '待定'}</Text>
          </View>
        </View>

        <View style={styles.actionButtons}>
          <TouchableOpacity style={styles.manageButton} onPress={() => fetchParticipants(item)} activeOpacity={0.8}>
            <View style={styles.manageButtonContent}>
              <Text style={styles.manageButtonText}>报名管理</Text>
              {(item.pendingCount > 0 || item.quitRequestedCount > 0) && (
                <View style={styles.badge}>
                  <Text style={styles.badgeText}>{(item.pendingCount || 0) + (item.quitRequestedCount || 0)}</Text>
                </View>
              )}
            </View>
          </TouchableOpacity>
          <TouchableOpacity style={styles.deleteButton} onPress={() => handleDeleteActivity(item.id)} activeOpacity={0.8}>
            <Text style={styles.deleteButtonText}>删除</Text>
          </TouchableOpacity>
        </View>
      </View>
    </View>
  );

  const handleQuitFromManagement = async (activityId) => {
    Alert.alert(
      '确认退出',
      '确定要退出此活动吗？',
      [
        { text: '取消', style: 'cancel' },
        {
          text: '确定',
          onPress: async () => {
            const user = await storage.getUser();
            if (!user) {
              Alert.alert('提示', '请先登录');
              navigation.navigate('Login');
              return;
            }

            try {
              await activityAPI.requestQuit(activityId, user.userId);
              Alert.alert('提示', '退出申请已提交，请等待发起人审核');
              fetchActivities();
            } catch (error) {
              Alert.alert('错误', error.response?.data?.message || '退出失败');
            }
          },
        },
      ]
    );
  };

  const renderJoinedActivity = ({ item }) => (
    <View style={styles.card}>
      <View style={styles.cardImageContainer}>
        {item.imageBase64 ? (
          <Image source={{ uri: `data:image/jpeg;base64,${item.imageBase64}` }} style={styles.cardImage} />
        ) : (
          <View style={styles.placeholderImage}>
            <Text style={styles.placeholderIcon}>🏕️</Text>
          </View>
        )}
      </View>

      <View style={styles.cardContent}>
        <View style={styles.titleRow}>
          <Text style={styles.activityName} numberOfLines={1}>{item.name}</Text>
          <View style={styles.statusTagsContainer}>
            <View style={[styles.statusTag, styles.approvedTag]}>
              <Text style={[styles.statusTagText, styles.approvedTagText]}>已报名</Text>
            </View>
          </View>
        </View>
        <Text style={styles.activityDescription} numberOfLines={2}>{item.description}</Text>

        <View style={styles.metaRow}>
          <View style={styles.metaItem}>
            <Text style={styles.metaIcon}>💰</Text>
            <Text style={styles.contractAmountText}>¥{item.contractAmount || 0}</Text>
          </View>
          <View style={styles.metaItem}>
            <Text style={styles.metaIcon}>👤</Text>
            <Text style={styles.metaText}>{item.creatorName}</Text>
          </View>
        </View>

        <TouchableOpacity style={styles.quitButton} onPress={() => handleQuitFromManagement(item.id)} activeOpacity={0.8}>
          <Text style={styles.quitButtonText}>申请退出</Text>
        </TouchableOpacity>
      </View>
    </View>
  );

  const renderParticipant = ({ item }) => (
    <View style={styles.participantCard}>
      <View style={styles.participantAvatar}>
        <Text style={styles.participantAvatarText}>{item.username?.charAt(0).toUpperCase()}</Text>
      </View>
      <View style={styles.participantInfo}>
        <Text style={styles.participantName}>{item.username}</Text>
        <Text style={styles.participantDetail}>{item.email}</Text>
        <Text style={styles.participantDetail}>{item.phone}</Text>
        {item.quitRequested && (
          <View style={[styles.quitBadge, { marginTop: 6 }]}>
            <Text style={styles.badgeText}>申请退出</Text>
          </View>
        )}
      </View>
      <View style={styles.participantActions}>
        {item.quitRequested ? (
          <>
            <TouchableOpacity style={[styles.actionBtn, styles.approveBtn]} onPress={() => handleApproveQuitRequest(item.id)}>
              <Text style={styles.actionBtnText}>同意</Text>
            </TouchableOpacity>
            <TouchableOpacity style={[styles.actionBtn, styles.rejectBtn]} onPress={() => handleRejectQuitRequest(item.id)}>
              <Text style={styles.actionBtnText}>拒绝</Text>
            </TouchableOpacity>
          </>
        ) : item.status === 'pending' ? (
          <>
            <TouchableOpacity style={[styles.actionBtn, styles.approveBtn]} onPress={() => handleApprove(item.id)}>
              <Text style={styles.actionBtnText}>同意</Text>
            </TouchableOpacity>
            <TouchableOpacity style={[styles.actionBtn, styles.rejectBtn]} onPress={() => handleReject(item.id)}>
              <Text style={styles.actionBtnText}>拒绝</Text>
            </TouchableOpacity>
          </>
        ) : (
          <View style={[styles.statusBadge, styles.approvedStatusBadge]}>
            <Text style={styles.statusBadgeText}>已通过</Text>
          </View>
        )}
      </View>
    </View>
  );

  const renderParticipantsModal = () => (
    <Modal visible={showParticipantsModal} animationType="slide" onRequestClose={() => setShowParticipantsModal(false)}>
      <SafeAreaView style={styles.modalSafeArea}>
        <StatusBar barStyle="dark-content" backgroundColor="#fff" />
        <View style={styles.modalHeader}>
          <TouchableOpacity onPress={() => setShowParticipantsModal(false)} style={styles.backButton}>
            <Text style={styles.backButtonText}>←</Text>
          </TouchableOpacity>
          <View style={styles.modalTitleContainer}>
            <Text style={styles.modalTitle}>报名管理</Text>
            {selectedActivity && <Text style={styles.modalSubtitle} numberOfLines={1}>{selectedActivity.name}</Text>}
          </View>
          <View style={{ width: 40 }} />
        </View>

        {loadingParticipants ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color="#6366F1" />
          </View>
        ) : participants.length === 0 ? (
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyIcon}>📋</Text>
            <Text style={styles.emptyText}>暂无报名信息</Text>
          </View>
        ) : (
          <FlatList
            data={participants}
            renderItem={renderParticipant}
            keyExtractor={(item) => String(item.id)}
            contentContainerStyle={styles.participantsList}
            showsVerticalScrollIndicator={false}
          />
        )}
      </SafeAreaView>
    </Modal>
  );

  const renderApprovedModal = () => (
    <Modal visible={showApprovedModal} animationType="slide" onRequestClose={() => setShowApprovedModal(false)}>
      <SafeAreaView style={styles.modalSafeArea}>
        <StatusBar barStyle="dark-content" backgroundColor="#fff" />
        <View style={styles.modalHeader}>
          <TouchableOpacity onPress={() => setShowApprovedModal(false)} style={styles.backButton}>
            <Text style={styles.backButtonText}>←</Text>
          </TouchableOpacity>
          <View style={styles.modalTitleContainer}>
            <Text style={styles.modalTitle}>参加人列表</Text>
            {selectedActivity && <Text style={styles.modalSubtitle} numberOfLines={1}>{selectedActivity.name}</Text>}
          </View>
          <View style={{ width: 40 }} />
        </View>

        {loadingParticipants ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color="#6366F1" />
          </View>
        ) : approvedParticipants.length === 0 ? (
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyIcon}>👥</Text>
            <Text style={styles.emptyText}>暂无参加人</Text>
          </View>
        ) : (
          <FlatList
            data={approvedParticipants}
            renderItem={({ item }) => (
              <View style={styles.approvedCard}>
                <View style={styles.participantAvatar}>
                  <Text style={styles.participantAvatarText}>{item.username?.charAt(0).toUpperCase()}</Text>
                </View>
                <View style={styles.approvedInfo}>
                  <Text style={styles.participantName}>{item.username}</Text>
                </View>
              </View>
            )}
            keyExtractor={(item) => String(item.id)}
            contentContainerStyle={styles.participantsList}
            showsVerticalScrollIndicator={false}
          />
        )}
      </SafeAreaView>
    </Modal>
  );

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="dark-content" backgroundColor="#F8FAFC" />
      <View style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backButton}>
            <Text style={styles.backButtonText}>←</Text>
          </TouchableOpacity>
          <Text style={styles.headerTitle}>活动管理</Text>
          <View style={{ width: 40 }} />
        </View>

        {loading ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color="#6366F1" />
          </View>
        ) : (
          <FlatList
            data={[{ type: 'section', title: '我创建的活动', count: createdActivities.length }, ...createdActivities.map(a => ({ ...a, type: 'created' })), { type: 'section', title: '我参加的活动', count: joinedActivities.length }, ...joinedActivities.map(a => ({ ...a, type: 'joined' }))]}
            renderItem={({ item, index }) => {
              if (item.type === 'section') {
                return (
                  <View style={styles.sectionHeader}>
                    <Text style={styles.sectionTitle}>{item.title}</Text>
                    <View style={styles.sectionBadge}>
                      <Text style={styles.sectionBadgeText}>{item.count}</Text>
                    </View>
                  </View>
                );
              }
              if (item.type === 'created') {
                return renderCreatedActivity({ item });
              }
              return renderJoinedActivity({ item });
            }}
            keyExtractor={(item, index) => item.type === 'section' ? `section-${item.title}` : `joined-${item.id}`}
            contentContainerStyle={styles.scrollContent}
            showsVerticalScrollIndicator={false}
            ListEmptyComponent={
              <View style={styles.emptyContainer}>
                <Text style={styles.emptyIcon}>🎭</Text>
                <Text style={styles.emptyText}>暂无活动</Text>
              </View>
            }
          />
        )}

        {renderParticipantsModal()}
        {renderApprovedModal()}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#F8FAFC',
    justifyContent: 'center',
    alignItems: 'center',
  },
  backButtonText: {
    fontSize: 20,
    color: '#1E1B4B',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1E1B4B',
  },
  content: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: 16,
    paddingBottom: 100,
  },
  section: {
    marginTop: 16,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 4,
    marginTop: 16,
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1E1B4B',
  },
  sectionBadge: {
    marginLeft: 8,
    backgroundColor: '#6366F1',
    borderRadius: 10,
    paddingHorizontal: 8,
    paddingVertical: 2,
  },
  sectionBadgeText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
  },
  listContent: {
    paddingHorizontal: 16,
    paddingBottom: 20,
  },
  card: {
    backgroundColor: '#fff',
    borderRadius: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 12,
    elevation: 3,
    overflow: 'hidden',
  },
  cardImageContainer: {
    position: 'relative',
  },
  cardImage: {
    width: '100%',
    height: 140,
    resizeMode: 'cover',
  },
  placeholderImage: {
    width: '100%',
    height: 140,
    backgroundColor: '#EEF2FF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  placeholderIcon: {
    fontSize: 40,
  },
  cardContent: {
    padding: 14,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 6,
  },
  activityName: {
    flex: 1,
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1E1B4B',
  },
  statusTagsContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  statusTag: {
    backgroundColor: '#ECFDF5',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  statusTagText: {
    fontSize: 11,
    fontWeight: '600',
    color: '#10B981',
  },
  statusTagTouchable: {
    backgroundColor: '#ECFDF5',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  approvedTag: {
    backgroundColor: '#ECFDF5',
  },
  approvedTagText: {
    color: '#10B981',
  },
  activityDescription: {
    fontSize: 13,
    color: '#6B7280',
    lineHeight: 18,
    marginBottom: 10,
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 10,
    gap: 16,
  },
  metaItem: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  metaIcon: {
    fontSize: 12,
    marginRight: 4,
  },
  metaText: {
    fontSize: 12,
    color: '#8E8E93',
  },
  contractAmountText: {
    fontSize: 12,
    color: '#EF4444',
    fontWeight: '600',
  },
  badgesRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 10,
  },
  badge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 8,
  },
  pendingBadge: {
    backgroundColor: '#FEF3C7',
  },
  quitBadge: {
    backgroundColor: '#F3E8FF',
  },
  badgeText: {
    fontSize: 11,
    fontWeight: '600',
    color: '#92400E',
  },
  quitBadgeText: {
    color: '#7C3AED',
  },
  actionButtons: {
    flexDirection: 'row',
    gap: 10,
  },
  manageButton: {
    flex: 1,
    backgroundColor: '#6366F1',
    paddingVertical: 10,
    borderRadius: 10,
    alignItems: 'center',
  },
  manageButtonText: {
    color: '#fff',
    fontSize: 13,
    fontWeight: '600',
  },
  manageButtonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  badge: {
    backgroundColor: '#EF4444',
    borderRadius: 10,
    minWidth: 18,
    height: 18,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 5,
  },
  badgeText: {
    color: '#fff',
    fontSize: 11,
    fontWeight: 'bold',
  },
  deleteButton: {
    flex: 1,
    backgroundColor: '#FEE2E2',
    paddingVertical: 10,
    borderRadius: 10,
    alignItems: 'center',
  },
  deleteButtonText: {
    color: '#EF4444',
    fontSize: 13,
    fontWeight: '600',
  },
  quitButton: {
    backgroundColor: '#FEE2E2',
    paddingVertical: 10,
    borderRadius: 10,
    alignItems: 'center',
    marginTop: 10,
  },
  quitButtonText: {
    color: '#EF4444',
    fontSize: 13,
    fontWeight: '600',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 40,
  },
  emptySection: {
    alignItems: 'center',
    padding: 40,
  },
  emptyIcon: {
    fontSize: 48,
    marginBottom: 12,
  },
  emptyText: {
    fontSize: 14,
    color: '#6B7280',
  },
  modalSafeArea: {
    flex: 1,
    backgroundColor: '#fff',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 16,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  modalTitleContainer: {
    flex: 1,
    alignItems: 'center',
    paddingHorizontal: 8,
  },
  modalTitle: {
    fontSize: 17,
    fontWeight: 'bold',
    color: '#1E1B4B',
  },
  modalSubtitle: {
    fontSize: 12,
    color: '#6B7280',
    marginTop: 2,
  },
  participantsList: {
    padding: 16,
  },
  participantCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 14,
    padding: 14,
    marginBottom: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 8,
    elevation: 2,
  },
  participantAvatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#6366F1',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  participantAvatarText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: 'bold',
  },
  participantInfo: {
    flex: 1,
  },
  approvedCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 14,
    marginBottom: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 8,
    elevation: 2,
  },
  approvedInfo: {
    flex: 1,
  },
  participantName: {
    fontSize: 15,
    fontWeight: '600',
    color: '#1E1B4B',
    marginBottom: 2,
  },
  participantDetail: {
    fontSize: 12,
    color: '#6B7280',
  },
  participantActions: {
    flexDirection: 'row',
    gap: 8,
  },
  actionBtn: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 8,
  },
  approveBtn: {
    backgroundColor: '#ECFDF5',
  },
  rejectBtn: {
    backgroundColor: '#FEE2E2',
  },
  actionBtnText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#374151',
  },
  statusBadge: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
  },
  approvedStatusBadge: {
    backgroundColor: '#ECFDF5',
  },
  statusBadgeText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#10B981',
  },
});