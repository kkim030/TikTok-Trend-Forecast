import { useState, useEffect, useCallback } from 'react';
import { getHashtagTrends, getMusicTrends, getCategoryTrends } from '../api/trendsApi';
import Spinner from '../components/ui/Spinner';
import ErrorBanner from '../components/ui/ErrorBanner';
import Badge from '../components/ui/Badge';

const TABS = [
  { key: 'hashtags', label: 'Hashtags', fetcher: getHashtagTrends },
  { key: 'music', label: 'Music', fetcher: getMusicTrends },
  { key: 'categories', label: 'Categories', fetcher: getCategoryTrends },
];

function formatPrefix(tabKey, keyword) {
  if (tabKey === 'hashtags') return `#${keyword}`;
  if (tabKey === 'music') return `\u266B ${keyword}`;
  return keyword;
}

export default function TrendsPage() {
  const [activeTab, setActiveTab] = useState('hashtags');
  const [trends, setTrends] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchTrends = useCallback(async (tabKey) => {
    setLoading(true);
    setError(null);
    const tab = TABS.find((t) => t.key === tabKey);
    try {
      const response = await tab.fetcher();
      setTrends(response.data);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to load trends. Please try again.');
      setTrends([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchTrends(activeTab);
  }, [activeTab, fetchTrends]);

  const handleTabChange = (tabKey) => {
    if (tabKey !== activeTab) {
      setActiveTab(tabKey);
    }
  };

  return (
    <div className="max-w-3xl mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Trending Now</h1>

      <div className="flex gap-6 mb-6 border-b border-gray-200">
        {TABS.map((tab) => (
          <button
            key={tab.key}
            onClick={() => handleTabChange(tab.key)}
            className={
              activeTab === tab.key
                ? 'text-pink-dark font-semibold border-b-2 border-pink-dark pb-1'
                : 'text-gray-500 hover:text-pink-dark pb-1'
            }
          >
            {tab.label}
          </button>
        ))}
      </div>

      {error && <ErrorBanner message={error} />}

      {loading ? (
        <div className="flex justify-center py-16">
          <Spinner size="lg" />
        </div>
      ) : trends.length === 0 ? (
        <p className="text-center text-gray-500 py-16">No trends available right now.</p>
      ) : (
        <div className="space-y-3">
          {trends.map((trend, index) => (
            <div
              key={trend.id ?? index}
              className="card flex flex-row items-center justify-between gap-4"
            >
              <span className="font-bold text-gray-900 min-w-[120px] truncate">
                {formatPrefix(activeTab, trend.keyword)}
              </span>

              <div className="bg-gray-200 rounded-full h-2 w-40 flex-shrink-0">
                <div
                  className="bg-pink-dark rounded-full h-2 transition-all duration-300"
                  style={{ width: `${Math.min(trend.velocityScore, 100)}%` }}
                />
              </div>

              <div className="flex items-center gap-3 flex-shrink-0">
                <Badge label={trend.velocityScore} variant="pink" />
                <span className="text-sm text-gray-600">
                  {(trend.engagementAvg * 100).toFixed(1)}%
                </span>
                <span className="text-sm text-gray-500">
                  {trend.viewCount?.toLocaleString() ?? '0'}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
