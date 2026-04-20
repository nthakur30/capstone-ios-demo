import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from 'recharts';
import type { HospitalWithMetrics } from '../api/types';

interface Props {
  hospitals: HospitalWithMetrics[];
  aiHospitalId: string;
  tradHospitalId: string;
}

export default function DUFBarChart({ hospitals, aiHospitalId, tradHospitalId }: Props) {
  const data = hospitals.slice(0, 8).map(h => ({
    name: h.name.split(' ').slice(-2).join(' '),
    duf: parseFloat(h.duf_score.toFixed(3)),
    id: h.id,
  }));

  const getColor = (id: string) => {
    if (id === aiHospitalId) return '#16a34a';
    if (id === tradHospitalId) return '#f59e0b';
    return '#334155';
  };

  return (
    <div className="bg-slate-800 border border-slate-700 rounded-xl p-5">
      <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-4">
        Hospital DUF Scores <span className="text-green-500 ml-2">■ AI Choice</span>
        <span className="text-yellow-500 ml-2">■ Traditional</span>
      </h3>
      <ResponsiveContainer width="100%" height={200}>
        <BarChart data={data} layout="vertical" margin={{ left: 60, right: 20 }}>
          <XAxis type="number" domain={['auto', 'auto']} tick={{ fill: '#94a3b8', fontSize: 11 }} />
          <YAxis type="category" dataKey="name" tick={{ fill: '#94a3b8', fontSize: 11 }} width={90} />
          <Tooltip
            contentStyle={{ background: '#1e293b', border: '1px solid #334155', borderRadius: 8 }}
            labelStyle={{ color: '#f1f5f9' }}
          />
          <Bar dataKey="duf" radius={[0, 4, 4, 0]}>
            {data.map(entry => (
              <Cell key={entry.id} fill={getColor(entry.id)} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
