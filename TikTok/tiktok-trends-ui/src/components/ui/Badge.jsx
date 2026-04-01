const variantClasses = {
  pink: 'bg-pink text-pink-darker',
  green: 'bg-green-100 text-green-800',
  yellow: 'bg-yellow-100 text-yellow-800',
  red: 'bg-red-100 text-red-800',
  gray: 'bg-gray-100 text-gray-600',
};

export default function Badge({ label, variant = 'pink' }) {
  return (
    <span
      className={`text-xs font-medium px-2 py-0.5 rounded-full ${variantClasses[variant] || variantClasses.pink}`}
    >
      {label}
    </span>
  );
}
