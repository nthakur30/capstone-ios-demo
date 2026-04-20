# Agentic EMS Routing System

Georgetown University — Senior Capstone Demo

A full-stack system that demonstrates how an AI-powered multi-agent routing engine outperforms traditional proximity-based EMS dispatch. Given an incident location and patient condition, the system scores every candidate hospital using a **Decision Utility Function (DUF)** and surfaces the medically optimal destination — not just the nearest one.

---

## How It Works

Traditional EMS dispatch routes to the **closest** hospital. This system routes to the **best** hospital by running three specialized agents concurrently, then scoring all hospitals on a composite metric.

### Agents (run in parallel)

| Agent | Responsibility |
|---|---|
| `PatientDataAgent` | Computes Revised Trauma Score (RTS) and severity multiplier from patient vitals and condition |
| `HospitalMetricsAgent` | Fetches ED overcrowding score, ED delay estimate, and specialty match level for each hospital |
| `TrafficAgent` | Estimates transport time and distance to each hospital |
| `RoutingCoordinator` | Aggregates outputs, computes DUF and risk scores, selects AI vs. traditional recommendation |

### Decision Utility Function (DUF)

```
DUF = 0.6 × (RTS × severity_multiplier × specialty_match / clinical_max)
    - 0.4 × (transport_time + ed_delay / logistics_max)
```

**AI recommendation** → highest DUF score  
**Traditional recommendation** → shortest distance  
**Delta Risk** → risk score difference between the two choices

---

## Project Structure

```
Software/
├── backend/              # Python FastAPI + agentic routing engine
│   ├── agents/           # PatientDataAgent, HospitalMetricsAgent, TrafficAgent, RoutingCoordinator
│   ├── models/           # Pydantic models (Hospital, Incident, RoutingResult)
│   ├── routers/          # API routes: /route, /hospitals, /simulation
│   ├── services/         # Data loader, stats service
│   ├── data/             # hospitals.json, incidents.json
│   └── main.py           # FastAPI app entry point
├── frontend/             # React + TypeScript + Vite dashboard
│   └── src/
│       ├── pages/        # RoutingPage, DashboardPage, SimulationPage
│       ├── components/   # HospitalCard, RouteMap, AgentTimeline, DUFBarChart, RiskDeltaChart
│       └── api/          # Typed API client
└── ios/                  # Native SwiftUI app (EMSRouting)
    └── EMSRouting/       # ContentView, RoutingView, DashboardView, SimulationView, OfflineRouter
```

---

## Tech Stack

| Layer | Stack |
|---|---|
| Backend | Python 3.12, FastAPI, Uvicorn, Pydantic v2 |
| Frontend | React 19, TypeScript, Vite, Tailwind CSS, Recharts, React-Leaflet |
| iOS | SwiftUI, AVFoundation (speech), offline routing fallback |

---

## Running Locally

### Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
# API available at http://localhost:8000
```

### Frontend

```bash
cd frontend
npm install
npm run dev
# App available at http://localhost:5173
```

### iOS

Open `ios/EMSRouting.xcodeproj` in Xcode and run on a simulator or device.  
The app connects to the backend at `http://localhost:8000` by default and includes an offline routing fallback.

---

## API Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/route` | Run agentic routing for an incident |
| `GET` | `/hospitals` | List all hospitals with current metrics |
| `POST` | `/simulation/run` | Run batch simulation comparing AI vs. traditional routing |

---

## Key Features

- **Parallel agent execution** — all three data agents run concurrently via `asyncio.gather`
- **Agent timeline visualization** — frontend renders per-agent start time and duration
- **AI vs. Traditional comparison** — side-by-side DUF scores, risk scores, and delta risk
- **Interactive map** — Leaflet map with hospital markers and incident location
- **Batch simulation** — run hundreds of incidents and compare aggregate outcomes
- **iOS offline mode** — `OfflineRouter.swift` provides local routing when backend is unreachable
