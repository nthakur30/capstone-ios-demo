import type { Hospital } from '../api/types';

const SPECIALTY_BADGES = [
  { key: 'cath_lab', label: 'Cath Lab', color: 'bg-red-900 text-red-300 border-red-700' },
  { key: 'stroke_center', label: 'Stroke', color: 'bg-purple-900 text-purple-300 border-purple-700' },
  { key: 'trauma_l1', label: 'Trauma L1', color: 'bg-orange-900 text-orange-300 border-orange-700' },
  { key: 'trauma_l2', label: 'Trauma L2', color: 'bg-yellow-900 text-yellow-300 border-yellow-700' },
  { key: 'pediatric', label: 'Pediatric', color: 'bg-blue-900 text-blue-300 border-blue-700' },
];

interface Props {
  hospital: Hospital;
}

export default function HospitalCard({ hospital: h }: Props) {
  const occupancy = h.ed_current_patients / h.ed_capacity;
  const overcrowdingScore = Math.max(0.5, Math.min(2.0, (occupancy * 2.5) - 1.0));
  const barColor = occupancy < 0.8 ? 'bg-green-500' : occupancy < 1.0 ? 'bg-yellow-500' : 'bg-red-500';
  const badges = SPECIALTY_BADGES.filter(b => h.capabilities[b.key as keyof typeof h.capabilities]);

  return (
    <div className="bg-slate-800 border border-slate-700 rounded-xl p-4 hover:border-slate-500 transition">
      <h3 className="text-sm font-semibold text-white mb-2 line-clamp-2 min-h-[40px]">{h.name}</h3>

      <div className="flex flex-wrap gap-1 mb-3 min-h-[24px]">
        {badges.length > 0
          ? badges.map(b => (
              <span key={b.key} className={`text-xs px-2 py-0.5 rounded-full border ${b.color}`}>{b.label}</span>
            ))
          : <span className="text-xs text-slate-500">General ED</span>
        }
      </div>

      <div className="space-y-1">
        <div className="flex justify-between text-xs text-slate-400">
          <span>ED Occupancy</span>
          <span className={occupancy >= 1.0 ? 'text-red-400' : 'text-slate-300'}>
            {h.ed_current_patients}/{h.ed_capacity} ({(occupancy * 100).toFixed(0)}%)
          </span>
        </div>
        <div className="h-2 bg-slate-700 rounded-full overflow-hidden">
          <div className={`h-full ${barColor} rounded-full transition-all`} style={{ width: `${Math.min(occupancy * 100, 100)}%` }} />
        </div>
        <div className="flex justify-between text-xs text-slate-500">
          <span>Overcrowding Score</span>
          <span>{overcrowdingScore.toFixed(2)}</span>
        </div>
      </div>
    </div>
  );
}
