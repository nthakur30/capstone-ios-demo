import axios from 'axios';
import type { IncidentRequest, RoutingResponse, Hospital, BatchStats } from './types';

const api = axios.create({ baseURL: 'http://localhost:8000' });

export const routeIncident = (incident: IncidentRequest): Promise<RoutingResponse> =>
  api.post('/api/route', incident).then(r => r.data);

export const getHospitals = (): Promise<Hospital[]> =>
  api.get('/api/hospitals').then(r => r.data);

export const refreshHospitals = (): Promise<Hospital[]> =>
  api.post('/api/hospitals/refresh').then(r => r.data);

export const getRandomIncident = (): Promise<IncidentRequest> =>
  api.get('/api/incidents/random').then(r => r.data);

export const runBatchSimulation = (): Promise<BatchStats> =>
  api.post('/api/simulate/batch').then(r => r.data);
