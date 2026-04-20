import { useState, useEffect } from 'react';
import HospitalCard from '../components/HospitalCard';
import { getHospitals, refreshHospitals } from '../api/client';
import type { Hospital } from '../api/types';

export default function DashboardPage() {
  const [hospitals, setHospitals] = useState<Hospital[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    getHospitals().then(setHospitals).finally(() => setLoading(false));
  }, []);

  const handleRefresh = async () => {
    setRefreshing(true);
    const updated = await refreshHospitals();
    setHospitals(updated);
    setRefreshing(false);
  };

  const avgOccupancy = hospitals.length
    ? hospitals.reduce((s, h) => s + h.ed_current_patients / h.ed_capacity, 0) / hospitals.length
    : 0;

  return (
    <div className="max-w-7xl mx-auto px-4 py-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Hospital Dashboard</h1>
          <p className="text-slate-400 text-sm mt-1">Real-time ED metrics across {hospitals.length} metro hospitals</p>
        </div>
        <div className="flex items-center gap-4">
          <div className="text-sm text-slate-400">
            Avg Occupancy: <span className={avgOccupancy >= 1.0 ? 'text-red-400 font-bold' : 'text-green-400 font-bold'}>
              {(avgOccupancy * 100).toFixed(0)}%
            </span>
          </div>
          <button onClick={handleRefresh} disabled={refreshing}
            className="px-4 py-2 bg-blue-700 hover:bg-blue-600 disabled:bg-slate-700 text-white text-sm rounded-lg transition">
            {refreshing ? 'Refreshing...' : '↻ Refresh Metrics'}
          </button>
        </div>
      </div>

      {loading ? (
        <div className="text-center text-slate-500 py-20">Loading hospital data...</div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {hospitals.map(h => <HospitalCard key={h.id} hospital={h} />)}
        </div>
      )}
    </div>
  );
}
