import type { AgentTrace } from '../api/types';

const AGENT_COLORS: Record<string, string> = {
  PatientDataAgent: 'bg-blue-500',
  HospitalMetricsAgent: 'bg-purple-500',
  TrafficAgent: 'bg-yellow-500',
  RoutingCoordinator: 'bg-green-500',
};

const AGENT_ICONS: Record<string, string> = {
  PatientDataAgent: '🧑‍⚕️',
  HospitalMetricsAgent: '🏥',
  TrafficAgent: '🚗',
  RoutingCoordinator: '🤖',
};

interface Props {
  traces: AgentTrace[];
}

export default function AgentTimeline({ traces }: Props) {
  const totalMs = Math.max(...traces.map(t => t.started_at_ms + t.duration_ms), 1);

  return (
    <div className="bg-slate-800 border border-slate-700 rounded-xl p-5">
      <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-4">Agent Execution Timeline</h3>
      <div className="space-y-3">
        {traces.map(trace => {
          const leftPct = (trace.started_at_ms / totalMs) * 100;
          const widthPct = Math.max((trace.duration_ms / totalMs) * 100, 2);
          const color = AGENT_COLORS[trace.agent] || 'bg-slate-500';
          return (
            <div key={trace.agent} className="flex items-center gap-3">
              <div className="w-44 text-xs text-slate-300 flex items-center gap-1.5 shrink-0">
                <span>{AGENT_ICONS[trace.agent] || '⚙️'}</span>
                <span>{trace.agent.replace('Agent','').replace('Coordinator','')}</span>
              </div>
              <div className="flex-1 relative h-6 bg-slate-700 rounded overflow-hidden">
                <div
                  className={`absolute h-full ${color} rounded opacity-80 flex items-center justify-end pr-1.5`}
                  style={{ left: `${leftPct}%`, width: `${widthPct}%` }}
                >
                  <span className="text-[10px] text-white font-mono">{trace.duration_ms.toFixed(0)}ms</span>
                </div>
              </div>
            </div>
          );
        })}
      </div>
      <div className="flex justify-between text-xs text-slate-500 mt-2">
        <span>0ms</span>
        <span>{totalMs.toFixed(0)}ms total</span>
      </div>
    </div>
  );
}
