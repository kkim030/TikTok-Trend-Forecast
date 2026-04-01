import axios from 'axios';

const api = axios.create({
  baseURL: '/api/v1',
  headers: { 'Content-Type': 'application/json' },
  timeout: 15000,
});

// Attach JWT to every request
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('tiktok_jwt');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Handle 401 globally — redirect to landing (skip for auth routes)
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const isAuthRoute = error.config?.url?.startsWith('/auth');
    if (error.response?.status === 401 && !isAuthRoute) {
      localStorage.removeItem('tiktok_jwt');
      localStorage.removeItem('tiktok_user');
      window.location.href = '/';
    }
    return Promise.reject(error);
  }
);

export default api;
