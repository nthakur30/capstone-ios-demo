import { useState } from 'react';
import RoutingPage from './pages/RoutingPage';
import DashboardPage from './pages/DashboardPage';
import SimulationPage from './pages/SimulationPage';

type Tab = 'routing' | 'dashboard' | 'simulation';

const TABS: { id: Tab; label: string; icon: string }[] = [
  { id: 'routing', label: 'Live Routing', icon: '🚑' },
  { id: 'dashboard', label: 'Hospital Dashboard', icon: '🏥' },
  { id: 'simulation', label: 'Simulation', icon: '📊' },
];

export default function App() {
  const [tab, setTab] = useState<Tab>('routing');

  return (
    <div className="min-h-screen bg-slate-900">
      {/* Header */}
      <header className="bg-slate-950 border-b border-slate-800 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex items-center h-14">
            <div className="flex items-center gap-3 mr-8">
              <span className="text-2xl">🚑</span>
              <div>
                <div className="text-white font-bold text-sm leading-none">Agentic EMS Routing</div>
                <div className="text-slate-500 text-xs">Georgetown Capstone Demo</div>
              </div>
            </div>
            <nav className="flex gap-1">
              {TABS.map(t => (
                <button key={t.id} onClick={() => setTab(t.id)}
                  className={`px-4 py-2 rounded-lg text-sm transition ${tab === t.id
                    ? 'bg-slate-800 text-white'
                    : 'text-slate-400 hover:text-white hover:bg-slate-800/50'}`}>
                  {t.icon} {t.label}
                </button>
              ))}
            </nav>
          </div>
        </div>
      </header>

      <main>
        {tab === 'routing' && <RoutingPage />}
        {tab === 'dashboard' && <DashboardPage />}
        {tab === 'simulation' && <SimulationPage />}
      </main>
    </div>
  );
}
