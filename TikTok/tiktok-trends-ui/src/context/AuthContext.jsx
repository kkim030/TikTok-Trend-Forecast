import { createContext, useContext, useState, useEffect, useCallback } from 'react';

const AuthContext = createContext(null);

const STORAGE_KEY_TOKEN = 'tiktok_jwt';
const STORAGE_KEY_USER = 'tiktok_user';

function loadInitialState() {
  const token = localStorage.getItem(STORAGE_KEY_TOKEN);
  const userJson = localStorage.getItem(STORAGE_KEY_USER);

  if (token && userJson) {
    try {
      const user = JSON.parse(userJson);
      return {
        token,
        userId: user.userId ?? null,
        tiktokHandle: user.tiktokHandle ?? null,
        displayName: user.displayName ?? null,
        avatarUrl: user.avatarUrl ?? null,
        isAuthenticated: true,
      };
    } catch {
      localStorage.removeItem(STORAGE_KEY_TOKEN);
      localStorage.removeItem(STORAGE_KEY_USER);
    }
  }

  return {
    token: null,
    userId: null,
    tiktokHandle: null,
    displayName: null,
    avatarUrl: null,
    isAuthenticated: false,
  };
}

export function AuthProvider({ children }) {
  const [auth, setAuth] = useState(loadInitialState);

  const login = useCallback((authResponse) => {
    const { token, userId, tiktokHandle, displayName, avatarUrl } = authResponse;

    localStorage.setItem(STORAGE_KEY_TOKEN, token);
    localStorage.setItem(
      STORAGE_KEY_USER,
      JSON.stringify({ userId, tiktokHandle, displayName, avatarUrl })
    );

    setAuth({
      token,
      userId,
      tiktokHandle,
      displayName,
      avatarUrl,
      isAuthenticated: true,
    });
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem(STORAGE_KEY_TOKEN);
    localStorage.removeItem(STORAGE_KEY_USER);

    setAuth({
      token: null,
      userId: null,
      tiktokHandle: null,
      displayName: null,
      avatarUrl: null,
      isAuthenticated: false,
    });
  }, []);

  return (
    <AuthContext.Provider value={{ ...auth, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
