# Agentic EMS Routing System

Georgetown University — Senior Capstone Demo

A full-stack system demonstrating how an AI-powered multi-agent routing engine outperforms traditional proximity-based EMS dispatch. Given an incident location and patient condition, the system scores every candidate hospital using a **Decision Utility Function (DUF)** and surfaces the medically optimal destination — not just the nearest one.

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
└── ios/                  # Native SwiftUI app — primary user interface
    └── EMSRouting/
        ├── ContentView.swift       # Tab container + offline/live mode toggle
        ├── RoutingView.swift       # Incident form, AI vs. traditional results, agent timeline
        ├── DashboardView.swift     # Hospital list with ED metrics
        ├── SimulationView.swift    # Batch simulation runner + statistics
        ├── OfflineRouter.swift     # On-device DUF engine (no backend needed)
        ├── APIClient.swift         # Backend API client (localhost:8000)
        ├── SpeechManager.swift     # Voice input for vitals
        └── Models.swift            # Shared data models
```

---

## Tech Stack

| Layer | Stack |
|---|---|
| Backend | Python 3.12, FastAPI, Uvicorn, Pydantic v2 |
| iOS App | SwiftUI, AVFoundation (speech), URLSession, offline routing |

---

## Running Locally

### Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
# API available at http://localhost:8000
```

### iOS App

Open `ios/EMSRouting.xcodeproj` in Xcode and run on a simulator or device.

**Demo / Offline Mode toggle** — visible at the top of every screen. When enabled, all routing runs on-device using the bundled hospitals data and the `OfflineRouter` DUF engine. No backend required.

When running on a physical device, update `APIClient.baseURL` in `APIClient.swift` to your Mac's local IP address.

---

## API Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/route` | Run agentic routing for an incident |
| `GET` | `/api/hospitals` | List all hospitals with current metrics |
| `POST` | `/api/simulate/batch` | Run batch simulation comparing AI vs. traditional routing |
| `GET` | `/api/incidents/random` | Return a random pre-generated incident |

---

## Key Features

- **Offline / Demo Mode** — full DUF scoring runs on-device with no backend; toggle at the top of the app
- **Parallel agent execution** — three data agents run concurrently via `asyncio.gather` on the backend
- **Voice input** — speak patient vitals directly into the routing form
- **AI vs. Traditional comparison** — side-by-side recommendations with delta risk score
- **Agent timeline** — visualizes per-agent start time and duration
- **Batch simulation** — 500-case paired t-test comparing AI vs. traditional aggregate outcomes
