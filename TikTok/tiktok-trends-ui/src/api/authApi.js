import api from './axiosInstance';

export const getTikTokAuthUrl = () => api.get('/auth/tiktok/authorize');
export const handleCallback = (code, state) => api.post('/auth/tiktok/callback', { code, state });
export const demoLogin = () => api.post('/auth/demo');
