import { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { getTikTokAuthUrl } from '../api/authApi';
import Spinner from '../components/ui/Spinner';
import ErrorBanner from '../components/ui/ErrorBanner';

export default function LandingPage() {
  const { isAuthenticated } = useAuth();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  if (isAuthenticated) {
    return <Navigate to="/trends" replace />;
  }

  const handleSignIn = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await getTikTokAuthUrl();
      const { authUrl } = response.data;
      window.location.href = authUrl;
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to connect to TikTok. Please try again.');
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-pink-light flex flex-col items-center justify-center px-4">
      <div className="text-center max-w-md w-full space-y-6">
        <h1 className="text-5xl font-bold text-pink-dark tracking-tight">
          TikTok Trends
        </h1>
        <p className="text-lg text-gray-600">
          AI-powered trend analysis for TikTok creators
        </p>

        <div className="pt-4 space-y-4">
          {error && <ErrorBanner message={error} />}

          <button
            onClick={handleSignIn}
            disabled={loading}
            className="btn-primary w-full max-w-xs mx-auto flex items-center justify-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed"
          >
            {loading ? (
              <Spinner size="sm" />
            ) : (
              <>
                <span className="text-xl" aria-hidden="true">&#9835;</span>
                <span>Sign in with TikTok</span>
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
