import api from './axiosInstance';

export const generateRecommendation = () => api.post('/recommendations');
export const getRecentRecommendations = () => api.get('/recommendations');
