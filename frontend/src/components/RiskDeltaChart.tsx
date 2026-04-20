import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, ReferenceLine } from 'recharts';
import type { BatchStats } from '../api/types';

interface Props {
  stats: BatchStats;
}

export default function RiskDeltaChart({ stats }: Props) {
  const conditionData = Object.entries(stats.by_condition).map(([cond, s]) => ({
    condition: cond,
    mean_delta: parseFloat(s.mean_delta.toFixed(2)),
    n: s.n,
  }));

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Mean Δ Risk Score', value: `+${stats.mean_delta.toFixed(2)}`, sub: `SD = ${stats.std_delta.toFixed(2)}`, color: 'text-green-400' },
          { label: 't-statistic', value: stats.t_statistic.toFixed(2), sub: `p < ${stats.p_value < 0.001 ? '0.001' : stats.p_value.toFixed(3)}`, color: 'text-blue-400' },
          { label: "Cohen's d", value: stats.cohens_d.toFixed(2), sub: stats.cohens_d >= 0.8 ? 'Large effect' : stats.cohens_d >= 0.5 ? 'Medium effect' : 'Small effect', color: 'text-purple-400' },
          { label: 'AI Wins', value: `${stats.ai_wins}/${stats.n_cases}`, sub: `${((stats.ai_wins / stats.n_cases) * 100).toFixed(1)}% of cases`, color: 'text-green-400' },
        ].map(card => (
          <div key={card.label} className="bg-slate-800 border border-slate-700 rounded-xl p-4 text-center">
            <div className="text-slate-400 text-xs mb-1">{card.label}</div>
            <div className={`text-2xl font-bold ${card.color}`}>{card.value}</div>
            <div className="text-slate-500 text-xs mt-1">{card.sub}</div>
          </div>
        ))}
      </div>

      <div className="bg-slate-800 border border-slate-700 rounded-xl p-5">
        <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-4">Mean Risk Score Delta by Condition</h3>
        <ResponsiveContainer width="100%" height={200}>
          <BarChart data={conditionData} margin={{ top: 5, right: 20, bottom: 5, left: 0 }}>
            <XAxis dataKey="condition" tick={{ fill: '#94a3b8', fontSize: 12 }} />
            <YAxis tick={{ fill: '#94a3b8', fontSize: 11 }} />
            <Tooltip
              contentStyle={{ background: '#1e293b', border: '1px solid #334155', borderRadius: 8 }}
              labelStyle={{ color: '#f1f5f9' }}
              // eslint-disable-next-line @typescript-eslint/no-explicit-any
              formatter={((v: unknown) => [`+${Number(v ?? 0).toFixed(2)} pts`, 'Mean Δ']) as any}
            />
            <ReferenceLine y={0} stroke="#475569" />
            <Bar dataKey="mean_delta" fill="#16a34a" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
