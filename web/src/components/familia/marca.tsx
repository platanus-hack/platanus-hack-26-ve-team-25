import { APP } from "@/lib/app";

/** La casita del ícono de la app con el nombre al lado, en el verde de la marca. */
export function Marca({ className = "" }: { className?: string }) {
  return (
    <span className={`flex items-center gap-3 font-bold text-verde ${className}`}>
      <svg className="size-[1.75em] shrink-0" viewBox="0 0 48 48" aria-hidden="true">
        <rect width="48" height="48" rx="12" fill="currentColor" />
        <path d="M24 11 9 24h4v13h22V24h4z" fill="#fff" />
        <rect x="21.5" y="27" width="5" height="10" rx="2.5" fill="currentColor" />
      </svg>
      {APP.nombreCorto}
    </span>
  );
}
