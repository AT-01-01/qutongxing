import { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Alert, ActivityIndicator, SafeAreaView, StatusBar, ScrollView } from 'react-native';
import { storage } from '../utils/storage';
import { activityAPI } from '../services/api';
import { setAuthToken } from '../services/api';

export default function ProfileScreen({ navigation }) {
  const [user, setUser] = useState(null);
  const [createdActivities, setCreatedActivities] = useState([]);
  const [joinedActivities, setJoinedActivities] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadUserData();
  }, []);

  const loadUserData = async () => {
    setLoading(true);
    const currentUser = await storage.getUser();
    setUser(currentUser);

    if (currentUser) {
      try {
        const [createdRes, joinedRes] = await Promise.all([
          activityAPI.getByCreator(currentUser.userId),
          activityAPI.getByParticipant(currentUser.userId),
        ]);
        setCreatedActivities(createdRes.data.data || []);
        setJoinedActivities(joinedRes.data.data || []);
      } catch (error) {
        console.error('Failed to load activities:', error);
      }
    }
    setLoading(false);
  };

  const handleLogout = async () => {
    Alert.alert(
      '退出登录',
      '确定要退出当前账号吗？',
      [
        { text: '取消', style: 'cancel' },
        {
          text: '退出',
          style: 'destructive',
          onPress: async () => {
            await storage.clear();
            setAuthToken(null);
            navigation.reset({
              index: 0,
              routes: [{ name: 'Login' }],
            });
          },
        },
      ]
    );
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#6366F1" />
        </View>
      </SafeAreaView>
    );
  }

  if (!user) {
    return (
      <SafeAreaView style={styles.safeArea}>
        <View style={styles.guestContainer}>
          <View style={styles.guestIcon}>
            <Text style={styles.guestIconText}>👤</Text>
          </View>
          <Text style={styles.guestTitle}>未登录</Text>
          <Text style={styles.guestSubtitle}>登录后查看您的个人资料</Text>
          <TouchableOpacity style={styles.loginButton} onPress={() => navigation.navigate('Login')}>
            <Text style={styles.loginButtonText}>立即登录</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="dark-content" backgroundColor="#F8FAFC" />
      <ScrollView showsVerticalScrollIndicator={false}>
        <View style={styles.container}>
          <View style={styles.profileHeader}>
            <View style={styles.headerBg} />
            <View style={styles.profileContent}>
              <View style={styles.avatarContainer}>
                <View style={styles.avatar}>
                  <Text style={styles.avatarText}>{user.username?.charAt(0).toUpperCase() || '?'}</Text>
                </View>
              </View>
              <Text style={styles.username}>{user.username}</Text>
              <Text style={styles.email}>{user.email || '暂无邮箱'}</Text>
              <View style={styles.statsRow}>
                <View style={styles.statItem}>
                  <Text style={styles.statNumber}>{createdActivities.length}</Text>
                  <Text style={styles.statLabel}>创建</Text>
                </View>
                <View style={styles.statDivider} />
                <View style={styles.statItem}>
                  <Text style={styles.statNumber}>{joinedActivities.length}</Text>
                  <Text style={styles.statLabel}>参加</Text>
                </View>
              </View>
            </View>
          </View>

          <View style={styles.sectionCard}>
            <Text style={styles.sectionTitle}>账号信息</Text>

            <View style={styles.infoRow}>
              <View style={styles.infoIcon}>
                <Text style={styles.infoIconText}>👤</Text>
              </View>
              <View style={styles.infoContent}>
                <Text style={styles.infoLabel}>用户名</Text>
                <Text style={styles.infoValue}>{user.username}</Text>
              </View>
            </View>

            <View style={styles.infoRow}>
              <View style={styles.infoIcon}>
                <Text style={styles.infoIconText}>📧</Text>
              </View>
              <View style={styles.infoContent}>
                <Text style={styles.infoLabel}>邮箱</Text>
                <Text style={styles.infoValue}>{user.email || '未填写'}</Text>
              </View>
            </View>

            <View style={styles.infoRow}>
              <View style={styles.infoIcon}>
                <Text style={styles.infoIconText}>📱</Text>
              </View>
              <View style={styles.infoContent}>
                <Text style={styles.infoLabel}>手机号</Text>
                <Text style={styles.infoValue}>{user.phone || '未填写'}</Text>
              </View>
            </View>
          </View>

          <View style={styles.sectionCard}>
            <Text style={styles.sectionTitle}>活动管理</Text>

            <TouchableOpacity style={styles.menuItem} onPress={() => navigation.navigate('ActivityManagement')}>
              <View style={styles.menuLeft}>
                <View style={[styles.menuIcon, { backgroundColor: '#EEF2FF' }]}>
                  <Text style={styles.menuIconText}>📋</Text>
                </View>
                <Text style={styles.menuText}>我的活动</Text>
              </View>
              <View style={styles.menuRight}>
                <View style={styles.menuBadge}>
                  <Text style={styles.menuBadgeText}>{createdActivities.length + joinedActivities.length}</Text>
                </View>
                <Text style={styles.menuArrow}>›</Text>
              </View>
            </TouchableOpacity>

            <TouchableOpacity style={styles.menuItem} onPress={() => navigation.navigate('ActivityList')}>
              <View style={styles.menuLeft}>
                <View style={[styles.menuIcon, { backgroundColor: '#ECFDF5' }]}>
                  <Text style={styles.menuIconText}>🔍</Text>
                </View>
                <Text style={styles.menuText}>发现活动</Text>
              </View>
              <Text style={styles.menuArrow}>›</Text>
            </TouchableOpacity>
          </View>

          <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
            <Text style={styles.logoutButtonText}>退出登录</Text>
          </TouchableOpacity>

          <Text style={styles.version}>趣同行 v1.0.0</Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F8FAFC',
  },
  guestContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 40,
  },
  guestIcon: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#EEF2FF',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 20,
  },
  guestIconText: {
    fontSize: 36,
  },
  guestTitle: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#1E1B4B',
    marginBottom: 8,
  },
  guestSubtitle: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 24,
  },
  loginButton: {
    backgroundColor: '#6366F1',
    paddingHorizontal: 32,
    paddingVertical: 14,
    borderRadius: 12,
  },
  loginButtonText: {
    color: '#fff',
    fontSize: 15,
    fontWeight: '600',
  },
  container: {
    flex: 1,
  },
  profileHeader: {
    backgroundColor: '#fff',
    borderBottomLeftRadius: 24,
    borderBottomRightRadius: 24,
    overflow: 'hidden',
  },
  headerBg: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    height: 100,
    backgroundColor: '#6366F1',
    borderBottomLeftRadius: 24,
    borderBottomRightRadius: 24,
  },
  profileContent: {
    paddingTop: 40,
    paddingBottom: 24,
    paddingHorizontal: 24,
    alignItems: 'center',
  },
  avatarContainer: {
    marginBottom: 16,
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#6366F1',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#6366F1',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 6,
  },
  avatarText: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#fff',
  },
  username: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#1E1B4B',
    marginBottom: 4,
  },
  email: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 20,
  },
  statsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F8FAFC',
    borderRadius: 16,
    paddingVertical: 16,
    paddingHorizontal: 32,
  },
  statItem: {
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  statNumber: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#6366F1',
  },
  statLabel: {
    fontSize: 12,
    color: '#6B7280',
    marginTop: 2,
  },
  statDivider: {
    width: 1,
    height: 30,
    backgroundColor: '#E5E7EB',
  },
  sectionCard: {
    backgroundColor: '#fff',
    borderRadius: 16,
    marginHorizontal: 16,
    marginTop: 16,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 12,
    elevation: 3,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1E1B4B',
    marginBottom: 16,
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  infoIcon: {
    width: 40,
    height: 40,
    borderRadius: 10,
    backgroundColor: '#F8FAFC',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 14,
  },
  infoIconText: {
    fontSize: 16,
  },
  infoContent: {
    flex: 1,
  },
  infoLabel: {
    fontSize: 12,
    color: '#9CA3AF',
    marginBottom: 2,
  },
  infoValue: {
    fontSize: 15,
    color: '#1E1B4B',
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  menuLeft: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  menuIcon: {
    width: 40,
    height: 40,
    borderRadius: 10,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  menuIconText: {
    fontSize: 16,
  },
  menuText: {
    fontSize: 15,
    color: '#1E1B4B',
  },
  menuRight: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  menuBadge: {
    backgroundColor: '#6366F1',
    borderRadius: 10,
    paddingHorizontal: 8,
    paddingVertical: 2,
    marginRight: 8,
  },
  menuBadgeText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
  },
  menuArrow: {
    fontSize: 20,
    color: '#9CA3AF',
  },
  logoutButton: {
    backgroundColor: '#FEE2E2',
    marginHorizontal: 16,
    marginTop: 24,
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  logoutButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#EF4444',
  },
  version: {
    textAlign: 'center',
    fontSize: 12,
    color: '#9CA3AF',
    marginTop: 24,
    marginBottom: 32,
  },
});