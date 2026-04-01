import api from './axiosInstance';

export const getAllTrends = () => api.get('/trends');
export const getHashtagTrends = () => api.get('/trends/hashtags');
export const getMusicTrends = () => api.get('/trends/music');
export const getCategoryTrends = () => api.get('/trends/categories');
export const getTopTrends = (type, limit = 10) => api.get('/trends/top', { params: { type, limit } });
