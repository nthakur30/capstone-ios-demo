import type { RoutingRecommendation } from '../api/types';

const SPECIALTY_LABELS: Record<number, { label: string; color: string }> = {
  1: { label: 'General ED', color: 'text-slate-400' },
  2: { label: 'Partial Match', color: 'text-yellow-400' },
  3: { label: 'Full Match ✓', color: 'text-green-400' },
};

interface Props {
  rec: RoutingRecommendation;
  isAI: boolean;
  deltaRisk?: number;
}

export default function RecommendationCard({ rec, isAI, deltaRisk }: Props) {
  const specialty = SPECIALTY_LABELS[rec.specialty_match] || SPECIALTY_LABELS[1];

  return (
    <div className={`rounded-xl border p-5 ${isAI
      ? 'bg-green-950 border-green-700'
      : 'bg-slate-800 border-slate-700'}`}>
      <div className="flex items-center justify-between mb-3">
        <span className={`text-xs font-bold uppercase tracking-wider px-2 py-1 rounded ${isAI ? 'bg-green-700 text-green-100' : 'bg-slate-700 text-slate-400'}`}>
          {isAI ? '🤖 AI Routing' : '📍 Traditional'}
        </span>
        {isAI && deltaRisk !== undefined && (
          <span className={`text-sm font-bold ${deltaRisk >= 0 ? 'text-green-400' : 'text-red-400'}`}>
            {deltaRisk >= 0 ? '+' : ''}{deltaRisk.toFixed(2)} pts
          </span>
        )}
      </div>

      <h3 className="text-lg font-bold text-white mb-4">{rec.hospital_name}</h3>

      <div className="grid grid-cols-2 gap-3 text-sm">
        <div className="bg-slate-900/40 rounded-lg p-3">
          <div className="text-slate-400 text-xs mb-1">Transport Time</div>
          <div className="text-white font-semibold">{rec.transport_time.toFixed(1)} min</div>
        </div>
        <div className="bg-slate-900/40 rounded-lg p-3">
          <div className="text-slate-400 text-xs mb-1">ED Delay</div>
          <div className="text-white font-semibold">{rec.ed_delay.toFixed(1)} min</div>
        </div>
        <div className="bg-slate-900/40 rounded-lg p-3">
          <div className="text-slate-400 text-xs mb-1">Specialty Match</div>
          <div className={`font-semibold ${specialty.color}`}>{specialty.label}</div>
        </div>
        <div className="bg-slate-900/40 rounded-lg p-3">
          <div className="text-slate-400 text-xs mb-1">Risk Score</div>
          <div className="text-white font-semibold">{rec.risk_score.toFixed(2)}</div>
        </div>
        <div className="bg-slate-900/40 rounded-lg p-3">
          <div className="text-slate-400 text-xs mb-1">RTS</div>
          <div className="text-white font-semibold">{rec.rts.toFixed(2)} <span className="text-slate-400 text-xs">/ 7.84</span></div>
        </div>
        <div className="bg-slate-900/40 rounded-lg p-3">
          <div className="text-slate-400 text-xs mb-1">DUF Score</div>
          <div className="text-white font-semibold">{rec.duf_score.toFixed(3)}</div>
        </div>
      </div>
    </div>
  );
}
