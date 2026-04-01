const sizeClasses = {
  sm: 'h-4 w-4',
  md: 'h-6 w-6',
  lg: 'h-10 w-10',
};

export default function Spinner({ size = 'md' }) {
  return (
    <div
      className={`animate-spin rounded-full border-2 border-pink-dark border-t-transparent ${sizeClasses[size] || sizeClasses.md}`}
      role="status"
      aria-label="Loading"
    />
  );
}
