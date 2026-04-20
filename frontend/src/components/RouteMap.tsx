import { MapContainer, TileLayer, Popup, CircleMarker } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import type { HospitalWithMetrics } from '../api/types';

// Fix leaflet default icon
// eslint-disable-next-line @typescript-eslint/no-explicit-any
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
});

interface Props {
  patientLat: number;
  patientLng: number;
  hospitals: HospitalWithMetrics[];
  aiHospitalId: string;
  tradHospitalId: string;
}

export default function RouteMap({ patientLat, patientLng, hospitals, aiHospitalId, tradHospitalId }: Props) {
  return (
    <div className="bg-slate-800 border border-slate-700 rounded-xl overflow-hidden" style={{ height: 320 }}>
      <MapContainer
        center={[patientLat, patientLng]}
        zoom={11}
        style={{ height: '100%', width: '100%' }}
      >
        <TileLayer
          url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
          attribution='&copy; OpenStreetMap contributors &copy; CARTO'
        />
        {/* Patient marker */}
        <CircleMarker center={[patientLat, patientLng]} radius={10} color="#dc2626" fillColor="#dc2626" fillOpacity={0.9}>
          <Popup>🚑 Patient Location</Popup>
        </CircleMarker>
        {/* Hospital markers */}
        {hospitals.map(h => {
          const isAI = h.id === aiHospitalId;
          const isTrad = h.id === tradHospitalId;
          const color = isAI ? '#16a34a' : isTrad ? '#f59e0b' : '#475569';
          return (
            <CircleMarker key={h.id} center={[h.lat, h.lng]} radius={isAI || isTrad ? 9 : 6}
              color={color} fillColor={color} fillOpacity={0.85}>
              <Popup>
                <strong>{h.name}</strong><br/>
                DUF: {h.duf_score.toFixed(3)}<br/>
                {isAI && <span style={{color:'#16a34a'}}>✓ AI Choice</span>}
                {isTrad && <span style={{color:'#f59e0b'}}>📍 Traditional</span>}
              </Popup>
            </CircleMarker>
          );
        })}
      </MapContainer>
    </div>
  );
}
