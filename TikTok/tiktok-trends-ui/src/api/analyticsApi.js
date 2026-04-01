import api from './axiosInstance';

export const getPerformance = () => api.get('/analytics/performance');
