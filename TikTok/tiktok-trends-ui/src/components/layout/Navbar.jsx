import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

function NavLink({ to, label }) {
  const { pathname } = useLocation();
  const isActive = pathname === to || pathname.startsWith(to + '/');

  return (
    <Link
      to={to}
      className={`px-3 py-2 text-sm transition-colors ${
        isActive
          ? 'text-pink-dark font-semibold border-b-2 border-pink-dark'
          : 'text-gray-600 hover:text-pink-dark'
      }`}
    >
      {label}
    </Link>
  );
}

function Avatar({ avatarUrl, tiktokHandle }) {
  if (avatarUrl) {
    return (
      <img
        src={avatarUrl}
        alt={tiktokHandle}
        className="h-8 w-8 rounded-full object-cover border border-pink"
      />
    );
  }

  const initial = tiktokHandle ? tiktokHandle.charAt(0).toUpperCase() : '?';

  return (
    <div className="h-8 w-8 rounded-full bg-pink flex items-center justify-center text-sm font-semibold text-pink-darker">
      {initial}
    </div>
  );
}

export default function Navbar() {
  const { isAuthenticated, tiktokHandle, avatarUrl, logout } = useAuth();

  return (
    <nav className="sticky top-0 z-50 bg-white border-b border-pink">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-14">
          <Link
            to="/trends"
            className="text-lg font-bold text-pink-dark tracking-tight"
          >
            TikTok Trends
          </Link>

          <div className="flex items-center gap-1">
            <NavLink to="/trends" label="Trends" />
            {isAuthenticated && (
              <>
                <NavLink to="/recommendations" label="Recommendations" />
                <NavLink to="/analytics" label="Analytics" />
              </>
            )}
          </div>

          <div className="flex items-center gap-3">
            {isAuthenticated ? (
              <>
                <div className="flex items-center gap-2">
                  <Avatar avatarUrl={avatarUrl} tiktokHandle={tiktokHandle} />
                  <span className="text-sm text-gray-700 hidden sm:inline">
                    @{tiktokHandle}
                  </span>
                </div>
                <button
                  onClick={logout}
                  className="text-sm text-gray-500 hover:text-pink-dark transition-colors"
                >
                  Logout
                </button>
              </>
            ) : (
              <Link
                to="/"
                className="text-sm text-pink-dark font-medium hover:underline"
              >
                Sign In
              </Link>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
}
