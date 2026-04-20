import { useState } from 'react';
import RiskDeltaChart from '../components/RiskDeltaChart';
import { runBatchSimulation } from '../api/client';
import type { BatchStats } from '../api/types';

export default function SimulationPage() {
  const [stats, setStats] = useState<BatchStats | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleRun = async () => {
    setLoading(true);
    setError(null);
    try {
      const result = await runBatchSimulation();
      setStats(result);
    } catch (e: unknown) {
      const err = e as { response?: { data?: { detail?: string } } };
      setError(err?.response?.data?.detail || 'Simulation failed. Is the backend running?');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-5xl mx-auto px-4 py-6 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Batch Simulation</h1>
        <p className="text-slate-400 text-sm mt-1">
          Run 500 pre-generated EMS incidents and compare AI vs traditional routing
        </p>
      </div>

      <div className="bg-slate-800 border border-slate-700 rounded-xl p-6">
        <div className="flex items-start justify-between">
          <div>
            <h2 className="text-lg font-semibold text-white mb-2">500-Case Statistical Analysis</h2>
            <p className="text-slate-400 text-sm max-w-lg">
              Replicates the capstone paper methodology: 125 cases each of STEMI, STROKE, TRAUMA, and GENERAL.
              Statistical validation via paired t-test and Cohen's d effect size.
            </p>
          </div>
          <button onClick={handleRun} disabled={loading}
            className="px-6 py-3 bg-green-700 hover:bg-green-600 disabled:bg-slate-700 text-white font-bold rounded-lg transition ml-4 shrink-0">
            {loading ? (
              <span className="flex items-center gap-2">
                <span className="animate-spin">⚙️</span> Running...
              </span>
            ) : '▶ Run 500 Cases'}
          </button>
        </div>
      </div>

      {error && (
        <div className="bg-red-950 border border-red-700 rounded-xl p-4 text-red-300 text-sm">{error}</div>
      )}

      {loading && (
        <div className="text-center text-slate-400 py-10">
          <div className="text-4xl mb-3 animate-spin inline-block">⚙️</div>
          <div>Processing 500 EMS incidents through all 4 agents...</div>
          <div className="text-slate-500 text-sm mt-1">This may take 10-30 seconds</div>
        </div>
      )}

      {stats && !loading && <RiskDeltaChart stats={stats} />}
    </div>
  );
}
