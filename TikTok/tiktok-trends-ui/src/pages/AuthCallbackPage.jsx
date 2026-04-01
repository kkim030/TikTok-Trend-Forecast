import { useEffect, useState, useRef } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { handleCallback } from '../api/authApi';
import Spinner from '../components/ui/Spinner';
import ErrorBanner from '../components/ui/ErrorBanner';

export default function AuthCallbackPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [error, setError] = useState(null);
  const calledRef = useRef(false);

  useEffect(() => {
    if (calledRef.current) return;
    calledRef.current = true;

    const params = new URLSearchParams(window.location.search);
    const code = params.get('code');
    const state = params.get('state');

    if (!code || !state) {
      setError('Missing authorization parameters. Please try signing in again.');
      return;
    }

    handleCallback(code, state)
      .then((response) => {
        login(response.data);
        navigate('/trends', { replace: true });
      })
      .catch((err) => {
        setError(err.response?.data?.message || 'Authentication failed. Please try again.');
      });
  }, [login, navigate]);

  return (
    <div className="min-h-screen bg-pink-light flex items-center justify-center px-4">
      <div className="card max-w-sm w-full text-center space-y-4">
        {error ? (
          <>
            <ErrorBanner message={error} />
            <Link
              to="/"
              className="inline-block mt-4 text-pink-dark font-medium hover:underline"
            >
              Try again
            </Link>
          </>
        ) : (
          <>
            <Spinner size="lg" />
            <p className="text-gray-600 text-sm">
              Connecting your TikTok account...
            </p>
          </>
        )}
      </div>
    </div>
  );
}
