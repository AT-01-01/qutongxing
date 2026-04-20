import { useState, useCallback, useRef } from 'react';
import { View, Text, FlatList, Image, TouchableOpacity, StyleSheet, Alert, ActivityIndicator, SafeAreaView, StatusBar, TextInput, Modal } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { activityAPI } from '../services/api';
import { storage } from '../utils/storage';

export default function ActivityListScreen({ navigation }) {
  const [activities, setActivities] = useState([]);
  const [loading, setLoading] = useState(true);
  const [pendingApplications, setPendingApplications] = useState(0);
  const [quitRequests, setQuitRequests] = useState(0);
  const [searchKeyword, setSearchKeyword] = useState('');
  const [showSortModal, setShowSortModal] = useState(false);
  const [sortOption, setSortOption] = useState({ sortBy: '', sortOrder: '' });
  const keywordRef = useRef('');

  useFocusEffect(
    useCallback(() => {
      fetchActivities();
      fetchApplicationCounts();
    }, [sortOption])
  );

  const fetchApplicationCounts = async () => {
    const user = await storage.getUser();
    if (user?.userId) {
      try {
        const response = await activityAPI.getByCreator(user.userId);
        const data = response?.data?.data || [];
        const totalPending = data.reduce((sum, activity) => sum + (activity.pendingCount || 0), 0);
        const totalQuit = data.reduce((sum, activity) => sum + (activity.quitRequestedCount || 0), 0);
        setPendingApplications(totalPending);
        setQuitRequests(totalQuit);
      } catch (error) {
        console.error('Failed to fetch application counts:', error);
      }
    }
  };

  const fetchActivities = async (keyword = keywordRef.current) => {
    setLoading(true);
    const user = await storage.getUser();
    try {
      const params = {
        userId: user?.userId,
        keyword: keyword || undefined,
        sortBy: sortOption.sortBy || undefined,
        sortOrder: sortOption.sortOrder || undefined,
      };
      const response = await activityAPI.getAll(params);
      const data = response?.data?.data;
      setActivities(Array.isArray(data) ? data : []);
    } catch (error) {
      console.error('Failed to fetch activities:', error);
      setActivities([]);
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = () => {
    keywordRef.current = searchKeyword;
    fetchActivities(searchKeyword);
  };

  const handleSort = (sortBy, sortOrder) => {
    setSortOption({ sortBy, sortOrder });
    setShowSortModal(false);
  };

  const getSortLabel = () => {
    if (!sortOption.sortBy) return '默认排序';
    switch (sortOption.sortBy) {
      case 'contractAmount':
        return sortOption.sortOrder === 'desc' ? '契约金从高到低' : '契约金从低到高';
      case 'activityDate':
        return sortOption.sortOrder === 'desc' ? '时间从晚到早' : '时间从早到晚';
      case 'participantCount':
        return '按报名人数';
      default:
        return '默认排序';
    }
  };

  const handleJoinActivity = async (activityId) => {
    Alert.alert(
      '确认报名',
      '确定要报名参加此活动吗？',
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
              await activityAPI.join(activityId, user.userId);
              Alert.alert('提示', '申请已提交，请等待发起人审核');
              fetchActivities();
            } catch (error) {
              Alert.alert('错误', error.response?.data?.message || '报名失败');
            }
          },
        },
      ],
      { cancelable: true }
    );
  };

  const handleQuitActivity = async (activityId) => {
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
      ],
      { cancelable: true }
    );
  };

  const handleCancelApplication = async (activityId) => {
    Alert.alert(
      '确认取消申请',
      '确定要取消报名申请吗？',
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
              await activityAPI.quit(activityId, user.userId);
              Alert.alert('提示', '已取消报名申请');
              fetchActivities();
            } catch (error) {
              Alert.alert('错误', error.response?.data?.message || '取消失败');
            }
          },
        },
      ],
      { cancelable: true }
    );
  };

  const renderActivityCard = ({ item }) => {
    if (!item) return null;

    const getJoinButton = () => {
      const status = item.joinStatus;
      if (status === 'approved') {
        return (
          <View style={styles.buttonRow}>
            <View style={[styles.statusBadge, styles.approvedStatusBadge]}>
              <Text style={styles.statusBadgeText}>✓ 已报名</Text>
            </View>
            <TouchableOpacity
              style={[styles.actionButton, styles.quitActionButton]}
              onPress={() => handleQuitActivity(item.id)}
            >
              <Text style={styles.actionButtonText}>申请退出</Text>
            </TouchableOpacity>
          </View>
        );
      }
      if (status === 'pending') {
        return (
          <View style={styles.buttonRow}>
            <View style={[styles.statusBadge, styles.pendingStatusBadge]}>
              <Text style={[styles.statusBadgeText, styles.pendingStatusBadgeText]}>⏳ 审核中</Text>
            </View>
            <TouchableOpacity
              style={[styles.actionButton, styles.cancelActionButton]}
              onPress={() => handleCancelApplication(item.id)}
            >
              <Text style={styles.actionButtonText}>取消申请</Text>
            </TouchableOpacity>
          </View>
        );
      }
      if (status === 'rejected') {
        return (
          <View style={styles.buttonRow}>
            <View style={[styles.statusBadge, styles.rejectedStatusBadge]}>
              <Text style={[styles.statusBadgeText, styles.rejectedStatusBadgeText]}>✕ 已拒绝</Text>
            </View>
            <TouchableOpacity
              style={[styles.actionButton, styles.deleteActionButton]}
              onPress={() => handleCancelApplication(item.id)}
            >
              <Text style={styles.actionButtonText}>删除记录</Text>
            </TouchableOpacity>
          </View>
        );
      }
      return (
        <TouchableOpacity
          style={[styles.actionButton, styles.joinActionButton]}
          onPress={() => handleJoinActivity(item.id)}
        >
          <Text style={styles.actionButtonText}>立即报名</Text>
        </TouchableOpacity>
      );
    };

    return (
      <View style={styles.card}>
        <View style={styles.cardImageContainer}>
          {item.imageBase64 ? (
            <Image
              source={{ uri: `data:image/jpeg;base64,${item.imageBase64}` }}
              style={styles.cardImage}
            />
          ) : (
            <View style={styles.placeholderImage}>
              <Text style={styles.placeholderIcon}>🏕️</Text>
              <Text style={styles.placeholderText}>活动图片</Text>
            </View>
          )}
          <View style={styles.imageOverlay}>
            <View style={styles.statsBadge}>
              <Text style={styles.statsBadgeText}>已报名 {item.approvedCount || 0} 人</Text>
            </View>
          </View>
        </View>

        <View style={styles.cardContent}>
          <Text style={styles.activityName} numberOfLines={1}>{item.name || '无标题'}</Text>
          <Text style={styles.activityDescription} numberOfLines={2}>{item.description || '无描述'}</Text>

          <View style={styles.metaRow}>
            <View style={styles.metaItem}>
              <Text style={styles.metaIcon}>👤</Text>
              <Text style={styles.metaText}>{item.creatorName || '未知'}</Text>
            </View>
            <View style={styles.metaItem}>
              <Text style={styles.metaIcon}>💰</Text>
              <Text style={styles.contractAmountText}>¥{item.contractAmount || 0}</Text>
            </View>
            <View style={styles.metaItem}>
              <Text style={styles.metaIcon}>📅</Text>
              <Text style={styles.metaText}>{item.activityDate ? item.activityDate.split('T')[0] : '待定'}</Text>
            </View>
          </View>

          {getJoinButton()}
        </View>
      </View>
    );
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="dark-content" backgroundColor="#F8FAFC" />
      <View style={styles.container}>
        <View style={styles.header}>
          <Text style={styles.headerTitle}>发现活动</Text>
          <Text style={styles.headerSubtitle}>精彩活动，等你参与</Text>
        </View>

        <View style={styles.searchSection}>
          <View style={styles.searchContainer}>
            <Text style={styles.searchIcon}>🔍</Text>
            <TextInput
              style={styles.searchInput}
              placeholder="搜索活动名称或描述"
              placeholderTextColor="#BDBDBD"
              value={searchKeyword}
              onChangeText={(text) => {
                setSearchKeyword(text);
                keywordRef.current = text;
                if (text === '') {
                  fetchActivities('');
                }
              }}
              onSubmitEditing={handleSearch}
              returnKeyType="search"
            />
            {searchKeyword.length > 0 && (
              <TouchableOpacity onPress={() => {
                const emptyKeyword = '';
                setSearchKeyword(emptyKeyword);
                keywordRef.current = emptyKeyword;
                fetchActivities(emptyKeyword);
              }}>
                <Text style={styles.clearIcon}>✕</Text>
              </TouchableOpacity>
            )}
          </View>
          <TouchableOpacity style={styles.sortButton} onPress={() => setShowSortModal(true)}>
            <Text style={styles.sortButtonText}>{getSortLabel()}</Text>
          </TouchableOpacity>
        </View>

        <Modal visible={showSortModal} transparent animationType="fade" onRequestClose={() => setShowSortModal(false)}>
          <View style={styles.modalOverlay}>
            <View style={styles.modalContent}>
              <Text style={styles.modalTitle}>选择排序方式</Text>

              <TouchableOpacity style={styles.sortOption} onPress={() => handleSort('', '')}>
                <Text style={styles.sortOptionText}>默认排序</Text>
                {!sortOption.sortBy && <Text style={styles.checkmark}>✓</Text>}
              </TouchableOpacity>

              <TouchableOpacity style={styles.sortOption} onPress={() => handleSort('contractAmount', 'desc')}>
                <Text style={styles.sortOptionText}>契约金从高到低</Text>
                {sortOption.sortBy === 'contractAmount' && sortOption.sortOrder === 'desc' && <Text style={styles.checkmark}>✓</Text>}
              </TouchableOpacity>

              <TouchableOpacity style={styles.sortOption} onPress={() => handleSort('contractAmount', 'asc')}>
                <Text style={styles.sortOptionText}>契约金从低到高</Text>
                {sortOption.sortBy === 'contractAmount' && sortOption.sortOrder === 'asc' && <Text style={styles.checkmark}>✓</Text>}
              </TouchableOpacity>

              <TouchableOpacity style={styles.sortOption} onPress={() => handleSort('activityDate', 'desc')}>
                <Text style={styles.sortOptionText}>活动时间从晚到早</Text>
                {sortOption.sortBy === 'activityDate' && sortOption.sortOrder === 'desc' && <Text style={styles.checkmark}>✓</Text>}
              </TouchableOpacity>

              <TouchableOpacity style={styles.sortOption} onPress={() => handleSort('activityDate', 'asc')}>
                <Text style={styles.sortOptionText}>活动时间从早到晚</Text>
                {sortOption.sortBy === 'activityDate' && sortOption.sortOrder === 'asc' && <Text style={styles.checkmark}>✓</Text>}
              </TouchableOpacity>

              <TouchableOpacity style={styles.sortOption} onPress={() => handleSort('participantCount', 'desc')}>
                <Text style={styles.sortOptionText}>按报名人数</Text>
                {sortOption.sortBy === 'participantCount' && <Text style={styles.checkmark}>✓</Text>}
              </TouchableOpacity>

              <TouchableOpacity style={styles.modalCancelButton} onPress={() => setShowSortModal(false)}>
                <Text style={styles.modalCancelText}>取消</Text>
              </TouchableOpacity>
            </View>
          </View>
        </Modal>

        <View style={styles.content}>
          {loading ? (
            <View style={styles.loadingContainer}>
              <ActivityIndicator size="large" color="#6366F1" />
            </View>
          ) : activities.length === 0 ? (
            <View style={styles.emptyContainer}>
              <Text style={styles.emptyIcon}>🎭</Text>
              <Text style={styles.emptyText}>暂无活动</Text>
              <Text style={styles.emptySubtext}>快来发布第一个活动吧</Text>
            </View>
          ) : (
            <FlatList
              data={activities}
              renderItem={renderActivityCard}
              keyExtractor={(item) => String(item.id)}
              contentContainerStyle={styles.list}
              showsVerticalScrollIndicator={false}
            />
          )}
        </View>

        <View style={styles.bottomTabBar}>
          <TouchableOpacity style={styles.tabItem} onPress={() => {
            setSearchKeyword('');
            keywordRef.current = '';
            fetchActivities('');
          }}>
            <View style={styles.tabIconContainer}>
              <Text style={styles.tabIcon}>🏠</Text>
            </View>
            <Text style={[styles.tabText, styles.tabTextActive]}>首页</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.tabItem}
            onPress={() => navigation.navigate('CreateActivity')}
          >
            <View style={styles.tabIconContainer}>
              <View style={styles.publishIcon}>
                <Text style={styles.publishIconText}>✦</Text>
              </View>
            </View>
            <Text style={styles.tabText}>发布</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.tabItem}
            onPress={() => navigation.navigate('ActivityManagement')}
          >
            <View style={styles.tabIconContainer}>
              <Text style={styles.tabIcon}>📋</Text>
              {(pendingApplications + quitRequests) > 0 && (
                <View style={styles.tabBadge}>
                  <Text style={styles.tabBadgeText}>{pendingApplications + quitRequests}</Text>
                </View>
              )}
            </View>
            <Text style={styles.tabText}>管理</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.tabItem}
            onPress={() => navigation.navigate('Profile')}
          >
            <View style={styles.tabIconContainer}>
              <Text style={styles.tabIcon}>👤</Text>
            </View>
            <Text style={styles.tabText}>我的</Text>
          </TouchableOpacity>
        </View>
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
    paddingTop: 16,
    paddingBottom: 12,
    backgroundColor: '#fff',
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1E1B4B',
    letterSpacing: 0.5,
  },
  headerSubtitle: {
    fontSize: 13,
    color: '#6B7280',
    marginTop: 2,
  },
  searchSection: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    gap: 10,
  },
  searchContainer: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 12,
    paddingHorizontal: 12,
    height: 42,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  searchIcon: {
    fontSize: 16,
    marginRight: 8,
  },
  searchInput: {
    flex: 1,
    fontSize: 15,
    color: '#1F2937',
  },
  clearIcon: {
    fontSize: 14,
    color: '#9CA3AF',
    padding: 4,
  },
  sortButton: {
    backgroundColor: '#fff',
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  sortButtonText: {
    fontSize: 13,
    color: '#6366F1',
    fontWeight: '500',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    width: '85%',
    backgroundColor: '#fff',
    borderRadius: 20,
    padding: 24,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1E1B4B',
    textAlign: 'center',
    marginBottom: 20,
  },
  sortOption: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  sortOptionText: {
    fontSize: 15,
    color: '#374151',
  },
  checkmark: {
    fontSize: 16,
    color: '#6366F1',
    fontWeight: 'bold',
  },
  modalCancelButton: {
    marginTop: 16,
    backgroundColor: '#F3F4F6',
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: 'center',
  },
  modalCancelText: {
    fontSize: 15,
    color: '#6B7280',
    fontWeight: '600',
  },
  content: {
    flex: 1,
  },
  list: {
    padding: 16,
    paddingBottom: 100,
  },
  card: {
    backgroundColor: '#fff',
    borderRadius: 20,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 12,
    elevation: 4,
    overflow: 'hidden',
  },
  cardImageContainer: {
    position: 'relative',
  },
  cardImage: {
    width: '100%',
    height: 160,
    resizeMode: 'cover',
  },
  placeholderImage: {
    width: '100%',
    height: 160,
    backgroundColor: '#EEF2FF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  placeholderIcon: {
    fontSize: 40,
    marginBottom: 8,
  },
  placeholderText: {
    color: '#8E8E93',
    fontSize: 14,
  },
  imageOverlay: {
    position: 'absolute',
    top: 12,
    left: 12,
    right: 12,
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  statsBadge: {
    backgroundColor: 'rgba(99, 102, 241, 0.9)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
  },
  statsBadgeText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
  },
  cardContent: {
    padding: 16,
  },
  activityName: {
    fontSize: 17,
    fontWeight: 'bold',
    color: '#1E1B4B',
    marginBottom: 6,
  },
  activityDescription: {
    fontSize: 13,
    color: '#6B7280',
    lineHeight: 20,
    marginBottom: 12,
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 14,
    gap: 16,
  },
  metaItem: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  metaIcon: {
    fontSize: 13,
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
  buttonRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  statusBadge: {
    flex: 1,
    paddingVertical: 10,
    paddingHorizontal: 12,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
  },
  statusBadgeText: {
    fontSize: 13,
    fontWeight: '600',
  },
  approvedStatusBadge: {
    borderColor: '#10B981',
    backgroundColor: '#ECFDF5',
  },
  approvedStatusBadgeText: {
    color: '#10B981',
  },
  pendingStatusBadge: {
    borderColor: '#F59E0B',
    backgroundColor: '#FFFBEB',
  },
  pendingStatusBadgeText: {
    color: '#F59E0B',
  },
  rejectedStatusBadge: {
    borderColor: '#9CA3AF',
    backgroundColor: '#F9FAFB',
  },
  rejectedStatusBadgeText: {
    color: '#9CA3AF',
  },
  actionButton: {
    flex: 1,
    paddingVertical: 10,
    paddingHorizontal: 12,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  actionButtonText: {
    color: '#fff',
    fontSize: 13,
    fontWeight: '600',
  },
  joinActionButton: {
    backgroundColor: '#6366F1',
  },
  quitActionButton: {
    backgroundColor: '#EF4444',
  },
  cancelActionButton: {
    backgroundColor: '#9CA3AF',
  },
  deleteActionButton: {
    backgroundColor: '#9CA3AF',
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
  emptyIcon: {
    fontSize: 60,
    marginBottom: 16,
  },
  emptyText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1E1B4B',
    marginBottom: 8,
  },
  emptySubtext: {
    fontSize: 14,
    color: '#6B7280',
    textAlign: 'center',
  },
  bottomTabBar: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    paddingVertical: 8,
    paddingBottom: 24,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 8,
  },
  tabItem: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 6,
  },
  tabIconContainer: {
    width: 28,
    height: 28,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 2,
  },
  tabIcon: {
    fontSize: 24,
    lineHeight: 28,
  },
  publishIcon: {
    width: 26,
    height: 26,
    borderRadius: 13,
    backgroundColor: '#6366F1',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#6366F1',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.4,
    shadowRadius: 4,
    elevation: 4,
  },
  publishIconText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: 'bold',
    marginTop: -1,
  },
  tabBadge: {
    position: 'absolute',
    top: -4,
    right: -8,
    backgroundColor: '#EF4444',
    borderRadius: 10,
    minWidth: 18,
    height: 18,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 4,
  },
  tabBadgeText: {
    color: '#fff',
    fontSize: 10,
    fontWeight: 'bold',
  },
  tabText: {
    fontSize: 11,
    color: '#9CA3AF',
    marginTop: 4,
  },
  tabTextActive: {
    color: '#6366F1',
    fontWeight: '600',
  },
});