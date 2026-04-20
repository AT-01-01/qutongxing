import axios from 'axios';
import * as SecureStore from 'expo-secure-store';

const BASE_URL = 'http://192.168.31.118:8086/api';

const api = axios.create({
  baseURL: BASE_URL,
  timeout: 15000,
  retry: 3,
  retryDelay: 1000,
});

let cachedToken = null;

api.interceptors.request.use(
  async (config) => {
    if (!cachedToken) {
      cachedToken = await SecureStore.getItemAsync('qutongxing_token');
    }
    if (cachedToken) {
      config.headers.Authorization = `Bearer ${cachedToken}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const { config } = error;

    if (!config || !config.retry || config.__retryCount >= config.retry) {
      if (error.response?.status === 401) {
        cachedToken = null;
        await SecureStore.deleteItemAsync('qutongxing_token');
        await SecureStore.deleteItemAsync('qutongxing_user');
      }
      return Promise.reject(error);
    }

    if (error.code === 'ECONNABORTED' ||
        error.message.includes('timeout') ||
        error.message.includes('Network Error') ||
        (error.response?.status >= 500 && error.response?.status < 600)) {
      config.__retryCount = config.__retryCount || 0;
      config.__retryCount += 1;

      console.log(`请求失败，${config.retryDelay}ms后重试 (${config.__retryCount}/${config.retry})`);
      console.log('请求URL:', config.url);

      return new Promise((resolve) => {
        setTimeout(() => {
          resolve(api(config));
        }, config.retryDelay);
      });
    }

    if (error.response?.status === 429) {
      const retryAfter = error.response?.headers?.['retry-after'];
      const waitTime = retryAfter ? parseInt(retryAfter) * 1000 : 5000;
      console.log(`请求被限流，等待${waitTime}ms后重试`);
      return new Promise((resolve) => {
        setTimeout(() => {
          resolve(api(config));
        }, waitTime);
      });
    }

    if (error.response?.status === 401) {
      cachedToken = null;
      await SecureStore.deleteItemAsync('qutongxing_token');
      await SecureStore.deleteItemAsync('qutongxing_user');
    }

    return Promise.reject(error);
  }
);

export const authAPI = {
  register: (data) => api.post('/auth/register', data),
  login: (data) => api.post('/auth/login', data),
  wechatLogin: (data) => api.post('/auth/login/wechat', data),
  qqLogin: (data) => api.post('/auth/login/qq', data),
  smsLogin: (data) => api.post('/auth/login/sms', data),
};

export const activityAPI = {
  getAll: (params) => {
    const cleanParams = {};
    if (params) {
      Object.keys(params).forEach(key => {
        if (params[key] !== undefined && params[key] !== null && params[key] !== '') {
          cleanParams[key] = params[key];
        }
      });
    }
    return api.get('/activities', { params: cleanParams });
  },
  getById: (id) => api.get(`/activities/${id}`),
  getByCreator: (creatorId) => api.get(`/activities/creator/${creatorId}`),
  getByParticipant: (userId) => api.get(`/activities/participant/${userId}`),
  create: (data) => api.post('/activities', data, {
    headers: { 'Content-Type': 'multipart/form-data' }
  }),
  join: (activityId, userId) => api.post(`/activities/${activityId}/join`, null, {
    params: { userId }
  }),
  quit: (activityId, userId) => api.post(`/activities/${activityId}/quit`, null, {
    params: { userId }
  }),
  requestQuit: (activityId, userId) => api.post(`/activities/${activityId}/request-quit`, null, {
    params: { userId }
  }),
  approveQuitRequest: (activityId, participantId) => api.post(`/activities/${activityId}/approve-quit/${participantId}`),
  rejectQuitRequest: (activityId, participantId) => api.post(`/activities/${activityId}/reject-quit/${participantId}`),
  delete: (activityId, userId) => api.delete(`/activities/${activityId}`, {
    params: { userId }
  }),
  getParticipants: (activityId) => api.get(`/activities/${activityId}/participants`),
  getApprovedParticipants: (activityId) => api.get(`/activities/${activityId}/approved-participants`),
  approveParticipant: (activityId, participantId) => api.post(`/activities/${activityId}/approve/${participantId}`),
  rejectParticipant: (activityId, participantId) => api.post(`/activities/${activityId}/reject/${participantId}`),
};

export const setAuthToken = (token) => {
  cachedToken = token;
};

export default api;