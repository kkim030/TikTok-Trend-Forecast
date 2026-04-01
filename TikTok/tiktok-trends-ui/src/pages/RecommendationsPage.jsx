import { useState, useEffect } from 'react';
import { generateRecommendation, getRecentRecommendations } from '../api/recommendationsApi';
import Spinner from '../components/ui/Spinner';
import ErrorBanner from '../components/ui/ErrorBanner';
import Badge from '../components/ui/Badge';

function confidenceVariant(score) {
  if (score >= 0.8) return 'green';
  if (score >= 0.6) return 'yellow';
  return 'red';
}

export default function RecommendationsPage() {
  const [recommendations, setRecommendations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [generating, setGenerating] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    getRecentRecommendations()
      .then((response) => {
        setRecommendations(response.data);
      })
      .catch((err) => {
        setError(err.response?.data?.message || 'Failed to load recommendations.');
      })
      .finally(() => {
        setLoading(false);
      });
  }, []);

  const handleGenerate = async () => {
    setGenerating(true);
    setError(null);
    try {
      const response = await generateRecommendation();
      setRecommendations((prev) => [response.data, ...prev]);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to generate recommendation. Please try again.');
    } finally {
      setGenerating(false);
    }
  };

  return (
    <div className="max-w-3xl mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">AI Video Concepts</h1>

      <button
        onClick={handleGenerate}
        disabled={generating}
        className="btn-primary w-full max-w-md mx-auto flex items-center justify-center gap-2 mb-8 disabled:opacity-60 disabled:cursor-not-allowed"
      >
        {generating ? <Spinner size="sm" /> : 'Generate New Concept'}
      </button>

      {error && (
        <div className="mb-6">
          <ErrorBanner message={error} />
        </div>
      )}

      {loading ? (
        <div className="flex justify-center py-16">
          <Spinner size="lg" />
        </div>
      ) : recommendations.length === 0 ? (
        <p className="text-center text-gray-500 py-16">
          No recommendations yet. Click Generate to create your first AI video concept.
        </p>
      ) : (
        <div className="space-y-4">
          {recommendations.map((rec, index) => (
            <div key={rec.id ?? index} className="card space-y-3">
              <div className="flex items-center justify-between gap-3">
                <h2 className="font-bold text-lg text-gray-900 truncate">
                  {rec.conceptTitle}
                </h2>
                <Badge
                  label={`${Math.round(rec.confidenceScore * 100)}%`}
                  variant={confidenceVariant(rec.confidenceScore)}
                />
              </div>

              <p className="text-gray-600 text-sm leading-relaxed">
                {rec.conceptDescription}
              </p>

              <div className="flex flex-wrap items-center justify-between gap-2 pt-1">
                <div className="flex items-center gap-3">
                  <span className="text-sm text-gray-500">
                    <span aria-hidden="true">{'\u266B'}</span> {rec.suggestedMusic}
                  </span>
                </div>
                <div className="flex flex-wrap gap-1">
                  {rec.suggestedHashtags?.map((tag, i) => (
                    <Badge key={i} label={tag} variant="pink" />
                  ))}
                </div>
              </div>

              <p className="text-xs text-gray-400">
                {new Date(rec.generatedAt).toLocaleDateString()}
              </p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
