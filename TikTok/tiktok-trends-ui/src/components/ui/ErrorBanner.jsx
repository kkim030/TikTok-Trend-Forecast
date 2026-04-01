export default function ErrorBanner({ message }) {
  if (!message) return null;

  return (
    <div className="bg-red-50 border border-red-300 text-red-700 rounded-lg p-3 text-sm">
      {message}
    </div>
  );
}
