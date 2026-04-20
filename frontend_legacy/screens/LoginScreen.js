import { useState, useEffect } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Alert, SafeAreaView, KeyboardAvoidingView, Platform, StatusBar, Animated, Dimensions } from 'react-native';
import { authAPI, setAuthToken } from '../services/api';
import { storage } from '../utils/storage';

const { width: SCREEN_WIDTH } = Dimensions.get('window');

export default function LoginScreen({ navigation }) {
  const [usernameOrPhone, setUsernameOrPhone] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const waveAnim1 = new Animated.Value(0);
  const waveAnim2 = new Animated.Value(0);
  const waveAnim3 = new Animated.Value(0);

  useEffect(() => {
    const createWaveAnimation = (animValue, delay, duration) => {
      return Animated.loop(
        Animated.sequence([
          Animated.timing(animValue, {
            toValue: 1,
            duration: duration,
            delay: delay,
            useNativeDriver: true,
          }),
          Animated.timing(animValue, {
            toValue: 0,
            duration: duration,
            delay: delay,
            useNativeDriver: true,
          }),
        ])
      );
    };

    Animated.parallel([
      createWaveAnimation(waveAnim1, 0, 3500),
      createWaveAnimation(waveAnim2, 600, 4500),
      createWaveAnimation(waveAnim3, 1200, 4000),
    ]).start();
  }, []);

  const handleLogin = async () => {
    if (!usernameOrPhone || !password) {
      Alert.alert('提示', '请输入账号和密码');
      return;
    }

    setLoading(true);
    try {
      const response = await authAPI.login({ usernameOrPhone, password });
      const { token, userId, username, email, phone } = response.data.data;

      await storage.setToken(token);
      await storage.setUser({ userId, username, email, phone });
      setAuthToken(token);

      Alert.alert('成功', '登录成功');
      navigation.navigate('ActivityList');
    } catch (error) {
      console.log('Login error:', error);
      let errorMessage;
      if (error.code === 'ERR_NETWORK' || error.message === 'Network Error') {
        errorMessage = '网络连接失败，请检查网络';
      } else if (error.response?.data?.message?.includes('用户不存在') || error.response?.status === 404) {
        errorMessage = '此用户未注册，请注册后再登录';
      } else {
        errorMessage = error.response?.data?.message || '登录失败，请检查网络连接';
      }
      Alert.alert('登录失败', errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const handleWechatLogin = async () => {
    setLoading(true);
    try {
      const response = await authAPI.wechatLogin({
        wechatId: 'test_wechat',
        username: '微信用户'
      });
      const { token, userId, username, email, phone } = response.data.data;

      await storage.setToken(token);
      await storage.setUser({ userId, username, email, phone });
      setAuthToken(token);

      Alert.alert('成功', '微信登录成功');
      navigation.navigate('ActivityList');
    } catch (error) {
      Alert.alert('错误', error.response?.data?.message || '登录失败');
    } finally {
      setLoading(false);
    }
  };

  const handleQQLogin = async () => {
    setLoading(true);
    try {
      const response = await authAPI.qqLogin({
        qqId: 'test_qq',
        username: 'QQ用户'
      });
      const { token, userId, username, email, phone } = response.data.data;

      await storage.setToken(token);
      await storage.setUser({ userId, username, email, phone });
      setAuthToken(token);

      Alert.alert('成功', 'QQ登录成功');
      navigation.navigate('ActivityList');
    } catch (error) {
      Alert.alert('错误', error.response?.data?.message || '登录失败');
    } finally {
      setLoading(false);
    }
  };

  const handleSmsLogin = async () => {
    setLoading(true);
    try {
      const response = await authAPI.smsLogin({
        phone: '13800138000',
        code: '123456'
      });
      const { token, userId, username, email, phone } = response.data.data;

      await storage.setToken(token);
      await storage.setUser({ userId, username, email, phone });
      setAuthToken(token);

      Alert.alert('成功', '短信登录成功');
      navigation.navigate('ActivityList');
    } catch (error) {
      Alert.alert('错误', error.response?.data?.message || '登录失败');
    } finally {
      setLoading(false);
    }
  };

  const SparkleDot = ({ style }) => (
    <Animated.View style={[styles.sparkleDot, style, {
      opacity: waveAnim1.interpolate({
        inputRange: [0, 0.5, 1],
        outputRange: [0.4, 1, 0.4],
      }),
      transform: [{
        scale: waveAnim1.interpolate({
          inputRange: [0, 0.5, 1],
          outputRange: [0.6, 1.5, 0.6],
        }),
      }],
    }]} />
  );

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="dark-content" backgroundColor="transparent" translucent />
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <View style={styles.container}>
          <View style={styles.backgroundContainer}>
            <View style={styles.gradientBg} />
            <View style={styles.waveContainer}>
              <Animated.View style={[styles.wave, styles.wave1, {
                transform: [{
                  translateY: waveAnim1.interpolate({
                    inputRange: [0, 1],
                    outputRange: [0, 18],
                  }),
                }],
                opacity: waveAnim1.interpolate({
                  inputRange: [0, 1],
                  outputRange: [0.12, 0.28],
                }),
              }]} />
              <Animated.View style={[styles.wave, styles.wave2, {
                transform: [{
                  translateY: waveAnim2.interpolate({
                    inputRange: [0, 1],
                    outputRange: [0, -25],
                  }),
                }],
                opacity: waveAnim2.interpolate({
                  inputRange: [0, 1],
                  outputRange: [0.08, 0.22],
                }),
              }]} />
              <Animated.View style={[styles.wave, styles.wave3, {
                transform: [{
                  translateY: waveAnim3.interpolate({
                    inputRange: [0, 1],
                    outputRange: [0, 15],
                  }),
                }],
                opacity: waveAnim3.interpolate({
                  inputRange: [0, 1],
                  outputRange: [0.15, 0.3],
                }),
              }]} />
            </View>
            <SparkleDot style={[styles.sparkle1]} />
            <SparkleDot style={[styles.sparkle2]} />
            <SparkleDot style={[styles.sparkle3]} />
            <SparkleDot style={[styles.sparkle4]} />
            <SparkleDot style={[styles.sparkle5]} />
            <SparkleDot style={[styles.sparkle6]} />
          </View>

          <View style={styles.topSection}>
            <View style={styles.brandRow}>
              <View style={styles.brandIcon}>
                <Text style={styles.brandIconText}>趣</Text>
              </View>
              <View style={styles.brandText}>
                <Text style={styles.brandName}>趣同行</Text>
                <Text style={styles.brandTagline}>一起出发，共享美好时光</Text>
              </View>
            </View>
          </View>

          <View style={styles.mainCard}>
            <Text style={styles.welcomeText}>欢迎回来</Text>
            <Text style={styles.welcomeSub}>请登录您的账号</Text>

            <View style={styles.form}>
              <View style={styles.inputWrapper}>
                <Text style={styles.inputLabel}>账号</Text>
                <TextInput
                  style={styles.input}
                  placeholder="请输入用户名或手机号"
                  placeholderTextColor="#BDBDBD"
                  value={usernameOrPhone}
                  onChangeText={setUsernameOrPhone}
                  autoCapitalize="none"
                />
              </View>

              <View style={styles.inputWrapper}>
                <Text style={styles.inputLabel}>密码</Text>
                <TextInput
                  style={styles.input}
                  placeholder="请输入密码"
                  placeholderTextColor="#BDBDBD"
                  value={password}
                  onChangeText={setPassword}
                  secureTextEntry
                />
              </View>

              <TouchableOpacity
                style={[styles.loginButton, loading && styles.loginButtonDisabled]}
                onPress={handleLogin}
                disabled={loading}
                activeOpacity={0.8}
              >
                <Text style={styles.loginButtonText}>
                  {loading ? '登录中...' : '登 录'}
                </Text>
              </TouchableOpacity>
            </View>

            <View style={styles.thirdPartySection}>
              <View style={styles.thirdPartyHeader}>
                <View style={styles.thirdPartyLine} />
                <Text style={styles.thirdPartyText}>其他登录方式</Text>
                <View style={styles.thirdPartyLine} />
              </View>

              <View style={styles.thirdPartyButtons}>
                <TouchableOpacity style={styles.thirdPartyButton} onPress={handleWechatLogin} activeOpacity={0.7}>
                  <View style={[styles.thirdPartyIcon, { backgroundColor: '#07C160' }]}>
                    <Text style={styles.thirdPartyIconText}>微</Text>
                  </View>
                  <Text style={styles.thirdPartyLabel}>微信</Text>
                </TouchableOpacity>

                <TouchableOpacity style={styles.thirdPartyButton} onPress={handleQQLogin} activeOpacity={0.7}>
                  <View style={[styles.thirdPartyIcon, { backgroundColor: '#12B7F5' }]}>
                    <Text style={styles.thirdPartyIconText}>Q</Text>
                  </View>
                  <Text style={styles.thirdPartyLabel}>QQ</Text>
                </TouchableOpacity>

                <TouchableOpacity style={styles.thirdPartyButton} onPress={handleSmsLogin} activeOpacity={0.7}>
                  <View style={[styles.thirdPartyIcon, { backgroundColor: '#FF6B00' }]}>
                    <Text style={styles.thirdPartyIconText}>短信</Text>
                  </View>
                  <Text style={styles.thirdPartyLabel}>短信</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>

          <View style={styles.footer}>
            <Text style={styles.footerText}>还没有账号？</Text>
            <TouchableOpacity onPress={() => navigation.navigate('Register')}>
              <Text style={styles.footerLink}>立即注册</Text>
            </TouchableOpacity>
          </View>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: '#EEF2FF',
  },
  keyboardView: {
    flex: 1,
  },
  container: {
    flex: 1,
    paddingHorizontal: 24,
  },
  backgroundContainer: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    overflow: 'hidden',
  },
  gradientBg: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: '#EEF2FF',
  },
  waveContainer: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
  wave: {
    position: 'absolute',
    width: SCREEN_WIDTH * 2.5,
    height: SCREEN_WIDTH * 2.5,
    borderRadius: SCREEN_WIDTH * 1.25,
    backgroundColor: '#818CF8',
  },
  wave1: {
    top: -SCREEN_WIDTH * 1.0,
    left: -SCREEN_WIDTH * 0.75,
  },
  wave2: {
    top: -SCREEN_WIDTH * 0.8,
    left: -SCREEN_WIDTH * 0.5,
    backgroundColor: '#A78BFA',
  },
  wave3: {
    top: -SCREEN_WIDTH * 0.9,
    left: -SCREEN_WIDTH * 0.6,
    backgroundColor: '#6366F1',
  },
  sparkleDot: {
    position: 'absolute',
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: '#FFFFFF',
    shadowColor: '#818CF8',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 1,
    shadowRadius: 8,
    elevation: 5,
  },
  sparkle1: { top: 100, left: 50 },
  sparkle2: { top: 180, right: 70 },
  sparkle3: { top: 280, left: 100 },
  sparkle4: { top: 380, right: 50 },
  sparkle5: { top: 520, left: 60 },
  sparkle6: { top: 620, right: 100 },
  topSection: {
    paddingTop: 40,
    paddingBottom: 24,
    zIndex: 10,
  },
  brandRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  brandIcon: {
    width: 52,
    height: 52,
    borderRadius: 14,
    backgroundColor: '#6366F1',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#6366F1',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.4,
    shadowRadius: 10,
    elevation: 8,
  },
  brandIconText: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#fff',
  },
  brandText: {
    marginLeft: 14,
  },
  brandName: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1E1B4B',
    letterSpacing: 1,
  },
  brandTagline: {
    fontSize: 13,
    color: '#6B7280',
    marginTop: 2,
    letterSpacing: 0.5,
  },
  mainCard: {
    flex: 1,
    backgroundColor: 'rgba(255, 255, 255, 0.96)',
    borderRadius: 24,
    padding: 28,
    shadowColor: '#6366F1',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.06,
    shadowRadius: 24,
    elevation: 10,
    zIndex: 10,
  },
  welcomeText: {
    fontSize: 26,
    fontWeight: 'bold',
    color: '#1E1B4B',
    marginBottom: 6,
  },
  welcomeSub: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 32,
  },
  form: {
    marginBottom: 24,
  },
  inputWrapper: {
    marginBottom: 20,
  },
  inputLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: '#374151',
    marginBottom: 8,
    opacity: 0.8,
  },
  input: {
    height: 52,
    backgroundColor: '#F9FAFB',
    borderRadius: 12,
    paddingHorizontal: 16,
    fontSize: 15,
    color: '#1F2937',
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  loginButton: {
    height: 52,
    backgroundColor: '#6366F1',
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 8,
    shadowColor: '#6366F1',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.4,
    shadowRadius: 10,
    elevation: 8,
  },
  loginButtonDisabled: {
    backgroundColor: '#A5B4FC',
    shadowOpacity: 0,
    elevation: 0,
  },
  loginButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    letterSpacing: 2,
  },
  thirdPartySection: {
    marginTop: 'auto',
  },
  thirdPartyHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 24,
  },
  thirdPartyLine: {
    flex: 1,
    height: 1,
    backgroundColor: '#E5E7EB',
  },
  thirdPartyText: {
    fontSize: 12,
    color: '#9CA3AF',
    paddingHorizontal: 12,
  },
  thirdPartyButtons: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 40,
  },
  thirdPartyButton: {
    alignItems: 'center',
  },
  thirdPartyIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 6,
    elevation: 4,
  },
  thirdPartyIconText: {
    fontSize: 14,
    color: '#fff',
    fontWeight: 'bold',
  },
  thirdPartyLabel: {
    fontSize: 12,
    color: '#6B7280',
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 24,
    zIndex: 10,
  },
  footerText: {
    fontSize: 14,
    color: '#6B7280',
  },
  footerLink: {
    fontSize: 14,
    color: '#6366F1',
    fontWeight: '600',
    marginLeft: 4,
  },
});