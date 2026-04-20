import { useState } from 'react';
import IncidentForm from '../components/IncidentForm';
import RecommendationCard from '../components/RecommendationCard';
import AgentTimeline from '../components/AgentTimeline';
import DUFBarChart from '../components/DUFBarChart';
import RouteMap from '../components/RouteMap';
import { routeIncident } from '../api/client';
import type { IncidentRequest, RoutingResponse } from '../api/types';

export default function RoutingPage() {
  const [result, setResult] = useState<RoutingResponse | null>(null);
  const [loading, setLoading] = useState(false);
  const [lastIncident, setLastIncident] = useState<IncidentRequest | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (incident: IncidentRequest) => {
    setLoading(true);
    setError(null);
    setLastIncident(incident);
    try {
      const res = await routeIncident(incident);
      setResult(res);
    } catch (e: unknown) {
      const err = e as { response?: { data?: { detail?: string } } };
      setError(err?.response?.data?.detail || 'Failed to connect to routing API. Is the backend running?');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 py-6 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Live EMS Routing</h1>
        <p className="text-slate-400 text-sm mt-1">AI-driven hospital routing vs traditional proximity-based dispatch</p>
      </div>

      {error && (
        <div className="bg-red-950 border border-red-700 rounded-xl p-4 text-red-300 text-sm">{error}</div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-1">
          <IncidentForm onSubmit={handleSubmit} loading={loading} />
        </div>

        <div className="lg:col-span-2 space-y-4">
          {result && lastIncident ? (
            <>
              <RouteMap
                patientLat={lastIncident.patient_lat}
                patientLng={lastIncident.patient_lng}
                hospitals={result.all_hospitals_scored}
                aiHospitalId={result.ai_recommendation.hospital_id}
                tradHospitalId={result.traditional_recommendation.hospital_id}
              />
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <RecommendationCard rec={result.ai_recommendation} isAI={true} deltaRisk={result.delta_risk} />
                <RecommendationCard rec={result.traditional_recommendation} isAI={false} />
              </div>
              <AgentTimeline traces={result.agent_traces} />
              <DUFBarChart
                hospitals={result.all_hospitals_scored}
                aiHospitalId={result.ai_recommendation.hospital_id}
                tradHospitalId={result.traditional_recommendation.hospital_id}
              />
            </>
          ) : (
            <div className="flex items-center justify-center h-64 bg-slate-800 border border-slate-700 rounded-xl text-slate-500">
              {loading ? (
                <div className="text-center">
                  <div className="text-3xl mb-3 animate-spin">⚙️</div>
                  <div>Running agents...</div>
                </div>
              ) : (
                <div className="text-center">
                  <div className="text-3xl mb-3">🚑</div>
                  <div>Submit an incident to see routing recommendations</div>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
