import { useState, useEffect, useMemo } from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { useAuth } from '../context/AuthContext';
import { getPerformance } from '../api/analyticsApi';
import Spinner from '../components/ui/Spinner';
import ErrorBanner from '../components/ui/ErrorBanner';

const METRICS = [
  { key: 'engagementRate', label: 'Engagement Rate' },
  { key: 'viewVelocity', label: 'View Velocity' },
  { key: 'followerGrowthRate', label: 'Follower Growth' },
  { key: 'avgWatchTimePct', label: 'Avg Watch Time %' },
  { key: 'shareRate', label: 'Share Rate' },
];

const GRADE_LABELS = [
  { key: 'engagementRate', label: 'Engagement Rate' },
  { key: 'viewVelocity', label: 'View Velocity' },
  { key: 'followerGrowth', label: 'Follower Growth' },
  { key: 'watchTime', label: 'Watch Time' },
  { key: 'shareRate', label: 'Share Rate' },
];

const gradeColor = {
  A: 'text-green-600',
  B: 'text-blue-600',
  C: 'text-yellow-600',
  D: 'text-orange-600',
  F: 'text-red-600',
};

function getGradeColorClass(grade) {
  if (!grade) return 'text-gray-400';
  return gradeColor[grade.charAt(0)] || 'text-gray-400';
}

function formatAxisValue(value, isVelocity) {
  if (isVelocity) return Number(value).toLocaleString();
  return `${(value * 100).toFixed(1)}%`;
}

export default function AnalyticsPage() {
  const { tiktokHandle } = useAuth();
  const [data, setData] = useState(null);
  const [selectedMetric, setSelectedMetric] = useState('engagementRate');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    getPerformance()
      .then((response) => {
        setData(response.data);
      })
      .catch((err) => {
        setError(err.response?.data?.message || 'Failed to load analytics data.');
      })
      .finally(() => {
        setLoading(false);
      });
  }, []);

  const isVelocity = selectedMetric === 'viewVelocity';

  const chartData = useMemo(() => {
    if (!data?.userSnapshots) return [];
    return data.userSnapshots.map((snap, i) => ({
      period: new Date(snap.periodStart).toLocaleDateString('en-US', {
        month: 'short',
        year: '2-digit',
      }),
      user: snap[selectedMetric],
      benchmark: data.benchmarks?.[i]?.[selectedMetric] ?? null,
    }));
  }, [data, selectedMetric]);

  const tooltipFormatter = (value) => {
    if (value === null || value === undefined) return 'N/A';
    return formatAxisValue(value, isVelocity);
  };

  const yAxisFormatter = (value) => formatAxisValue(value, isVelocity);

  if (loading) {
    return (
      <div className="flex justify-center py-24">
        <Spinner size="lg" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="max-w-3xl mx-auto px-4 py-8">
        <ErrorBanner message={error} />
      </div>
    );
  }

  const hasSnapshots = data?.userSnapshots && data.userSnapshots.length > 0;

  return (
    <div className="max-w-3xl mx-auto px-4 py-8 space-y-8">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Performance Analytics</h1>
        {tiktokHandle && (
          <p className="text-sm text-gray-500 mt-1">@{tiktokHandle}</p>
        )}
      </div>

      {!hasSnapshots ? (
        <p className="text-center text-gray-500 py-16">
          No performance data yet. Check back after your first weekly snapshot.
        </p>
      ) : (
        <>
          <div>
            <label htmlFor="metric-select" className="block text-sm font-medium text-gray-700 mb-1">
              Metric
            </label>
            <select
              id="metric-select"
              value={selectedMetric}
              onChange={(e) => setSelectedMetric(e.target.value)}
              className="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-pink-dark focus:border-transparent"
            >
              {METRICS.map((m) => (
                <option key={m.key} value={m.key}>
                  {m.label}
                </option>
              ))}
            </select>
          </div>

          <div className="card">
            <ResponsiveContainer width="100%" height={320}>
              <LineChart data={chartData} margin={{ top: 5, right: 20, bottom: 5, left: 10 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#FFB6C1" />
                <XAxis dataKey="period" tick={{ fontSize: 12 }} />
                <YAxis tickFormatter={yAxisFormatter} tick={{ fontSize: 12 }} />
                <Tooltip formatter={tooltipFormatter} />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="user"
                  stroke="#E91E8C"
                  strokeWidth={2}
                  dot={{ r: 4 }}
                  name="You"
                />
                <Line
                  type="monotone"
                  dataKey="benchmark"
                  stroke="#9CA3AF"
                  strokeWidth={2}
                  strokeDasharray="5 5"
                  dot={false}
                  name="Platform Benchmark"
                />
              </LineChart>
            </ResponsiveContainer>
          </div>

          {data.currentGrades && (
            <div>
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Grade Scorecard</h2>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                {GRADE_LABELS.map((item) => (
                  <div
                    key={item.key}
                    className="bg-white rounded-xl border p-4 text-center"
                  >
                    <p className="text-xs text-gray-500 mb-1">{item.label}</p>
                    <p className={`text-3xl font-bold ${getGradeColorClass(data.currentGrades[item.key])}`}>
                      {data.currentGrades[item.key] || '-'}
                    </p>
                  </div>
                ))}

                <div className="col-span-2 md:col-span-3 bg-white rounded-xl border-2 border-pink-dark p-4 text-center">
                  <p className="text-xs text-gray-500 mb-1">Overall</p>
                  <p className={`text-5xl font-bold ${getGradeColorClass(data.currentGrades.overall)}`}>
                    {data.currentGrades.overall || '-'}
                  </p>
                </div>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}
