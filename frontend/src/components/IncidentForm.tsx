import React, { useState } from 'react';
import type { ConditionType, IncidentRequest } from '../api/types';
import { getRandomIncident } from '../api/client';

interface Props {
  onSubmit: (incident: IncidentRequest) => void;
  loading: boolean;
}

// Presets tuned so AI and traditional diverge (demonstrating specialty routing benefit)
// STEMI Δ+2.64, STROKE Δ+4.82, TRAUMA Δ+5.88 — all AI wins with specialty match=3
const PRESETS: Record<string, IncidentRequest> = {
  'Critical STEMI': { patient_lat: 34.850, patient_lng: -79.850, condition: 'STEMI',   gcs: 10, sbp: 78,  rr: 24 },
  'Moderate Stroke':{ patient_lat: 35.450, patient_lng: -79.750, condition: 'STROKE',  gcs: 8,  sbp: 185, rr: 18 },
  'Major Trauma':   { patient_lat: 35.150, patient_lng: -80.150, condition: 'TRAUMA',  gcs: 6,  sbp: 62,  rr: 30 },
  'General Call':   { patient_lat: 35.048, patient_lng: -79.964, condition: 'GENERAL', gcs: 15, sbp: 128, rr: 16 },
};

export default function IncidentForm({ onSubmit, loading }: Props) {
  const [form, setForm] = useState<IncidentRequest>(PRESETS['Critical STEMI']);

  const handlePreset = (name: string) => setForm(PRESETS[name]);

  const handleRandom = async () => {
    const inc = await getRandomIncident();
    setForm(inc);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit(form);
  };

  const inputClass = "w-full bg-slate-700 border border-slate-600 rounded px-3 py-2 text-white focus:outline-none focus:border-blue-500";
  const labelClass = "block text-slate-400 text-sm mb-1";

  return (
    <div className="bg-slate-800 border border-slate-700 rounded-xl p-5">
      <h2 className="text-lg font-bold text-white mb-4 flex items-center gap-2">
        <span className="text-2xl">🚑</span> EMS Incident
      </h2>

      {/* Presets */}
      <div className="flex flex-wrap gap-2 mb-4">
        {Object.keys(PRESETS).map(name => (
          <button key={name} onClick={() => handlePreset(name)}
            className="text-xs px-3 py-1 rounded-full bg-slate-700 hover:bg-slate-600 border border-slate-600 text-slate-300 transition">
            {name}
          </button>
        ))}
        <button onClick={handleRandom}
          className="text-xs px-3 py-1 rounded-full bg-blue-900 hover:bg-blue-800 border border-blue-700 text-blue-300 transition">
          Random
        </button>
      </div>

      <form onSubmit={handleSubmit} className="space-y-3">
        <div>
          <label className={labelClass}>Condition</label>
          <select value={form.condition} onChange={e => setForm({...form, condition: e.target.value as ConditionType})}
            className={inputClass}>
            {(['STEMI', 'STROKE', 'TRAUMA', 'GENERAL'] as ConditionType[]).map(c => (
              <option key={c} value={c}>{c}</option>
            ))}
          </select>
        </div>

        <div className="grid grid-cols-3 gap-3">
          <div>
            <label className={labelClass}>GCS <span className="text-slate-500">(3-15)</span></label>
            <input type="number" min={3} max={15} value={form.gcs}
              onChange={e => setForm({...form, gcs: +e.target.value})} className={inputClass} />
          </div>
          <div>
            <label className={labelClass}>SBP <span className="text-slate-500">(mmHg)</span></label>
            <input type="number" min={0} max={300} value={form.sbp}
              onChange={e => setForm({...form, sbp: +e.target.value})} className={inputClass} />
          </div>
          <div>
            <label className={labelClass}>RR <span className="text-slate-500">(br/min)</span></label>
            <input type="number" min={0} max={60} value={form.rr}
              onChange={e => setForm({...form, rr: +e.target.value})} className={inputClass} />
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className={labelClass}>Lat</label>
            <input type="number" step="0.0001" value={form.patient_lat}
              onChange={e => setForm({...form, patient_lat: +e.target.value})} className={inputClass} />
          </div>
          <div>
            <label className={labelClass}>Lng</label>
            <input type="number" step="0.0001" value={form.patient_lng}
              onChange={e => setForm({...form, patient_lng: +e.target.value})} className={inputClass} />
          </div>
        </div>

        <button type="submit" disabled={loading}
          className="w-full py-3 bg-red-600 hover:bg-red-700 disabled:bg-slate-600 text-white font-bold rounded-lg transition text-sm">
          {loading ? 'Routing...' : 'Route Incident'}
        </button>
      </form>
    </div>
  );
}
