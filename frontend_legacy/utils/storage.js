import * as SecureStore from 'expo-secure-store';

const STORAGE_KEYS = {
  TOKEN: 'qutongxing_token',
  USER: 'qutongxing_user',
};

export const storage = {
  getToken: async () => {
    try {
      return await SecureStore.getItemAsync(STORAGE_KEYS.TOKEN);
    } catch {
      return null;
    }
  },
  
  setToken: async (token) => {
    try {
      await SecureStore.setItemAsync(STORAGE_KEYS.TOKEN, token);
    } catch (e) {
      console.error('Failed to set token:', e);
    }
  },
  
  removeToken: async () => {
    try {
      await SecureStore.deleteItemAsync(STORAGE_KEYS.TOKEN);
    } catch (e) {
      console.error('Failed to remove token:', e);
    }
  },
  
  getUser: async () => {
    try {
      const user = await SecureStore.getItemAsync(STORAGE_KEYS.USER);
      return user ? JSON.parse(user) : null;
    } catch {
      return null;
    }
  },
  
  setUser: async (user) => {
    try {
      await SecureStore.setItemAsync(STORAGE_KEYS.USER, JSON.stringify(user));
    } catch (e) {
      console.error('Failed to set user:', e);
    }
  },
  
  removeUser: async () => {
    try {
      await SecureStore.deleteItemAsync(STORAGE_KEYS.USER);
    } catch (e) {
      console.error('Failed to remove user:', e);
    }
  },
  
  clear: async () => {
    try {
      await SecureStore.deleteItemAsync(STORAGE_KEYS.TOKEN);
      await SecureStore.deleteItemAsync(STORAGE_KEYS.USER);
    } catch (e) {
      console.error('Failed to clear storage:', e);
    }
  },
};