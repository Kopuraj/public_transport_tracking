# 🏗️ SYSTEM ARCHITECTURE
## TransitLive Pro - Complete Real-Time System

---

## 📐 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                      🌍 INTERNET / CLOUD                        │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│              📡 TRANSIT LIVE PRO BACKEND                        │
│              (Node.js + Express + Socket.io)                    │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  REST API (HTTP) & WebSocket (Socket.io)                 │  │
│  │  • Authentication & Authorization                        │  │
│  │  • Trip Management                                       │  │
│  │  • GPS Processing & ETA Calculation                      │  │
│  │  • Crowd Intelligence Aggregation                        │  │
│  │  • Emergency Alert Broadcasting                          │  │
│  │  • Analytics Engine                                      │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          ↕↕↕↕                                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  🗄️ FIREBASE (Google Cloud)                              │  │
│  │  • Firestore Database (Real-time)                        │  │
│  │  • Firebase Authentication                               │  │
│  │  • Real-time Listeners                                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
          ↗                    ↑                    ↖
         ↙                     ↓                     ↘
    ┌─────────────┐    ┌──────────────┐    ┌──────────────┐
    │  📱 DRIVER  │    │  📱 PASSENGER│    │  👨‍💼 ADMIN   │
    │   APP       │    │   APP        │    │  DASHBOARD   │
    │  (Flutter)  │    │  (Flutter)   │    │  (Flutter)   │
    └─────────────┘    └──────────────┘    └──────────────┘
```

---

## 🔄 DETAILED DATA FLOW

### 1️⃣ AUTHENTICATION FLOW

```
┌────────────────────────────────────────────────────────┐
│                  USER SIGNUP/LOGIN                     │
└────────────────────────────────────────────────────────┘
         ↓
    ┌─────────────────────────────────────────────────┐
    │ 1. Flutter App sends email + password           │
    │    POST /api/auth/signup                        │
    └─────────────────────────────────────────────────┘
         ↓
    ┌─────────────────────────────────────────────────┐
    │ 2. Backend validates input                      │
    │    Creates Firebase Auth user                   │
    │    Stores user profile in Firestore             │
    └─────────────────────────────────────────────────┘
         ↓
    ┌─────────────────────────────────────────────────┐
    │ 3. Server generates JWT token (7 day expiry)    │
    │    Returns token + user data                    │
    └─────────────────────────────────────────────────┘
         ↓
    ┌─────────────────────────────────────────────────┐
    │ 4. Flutter App stores token locally             │
    │    (SharedPreferences)                          │
    │    Uses for all future requests                 │
    └─────────────────────────────────────────────────┘
```

---

### 2️⃣ REAL-TIME TRIP TRACKING FLOW

```
TIME: 07:00 - Trip Starts
┌──────────────────────────────────┐
│ DRIVER opens app → Initializes   │
│ POST /api/trips/initialize       │
│ vehicleId, routeId               │
└──────────────────────────────────┘
         ↓
      ✅ tripId = "trip_001"
      
TIME: 07:01 - Continuous GPS Updates
┌──────────────────────────────────────────────┐
│ DRIVER PHONE sends GPS every 5-10 seconds    │
│                                              │
│ POST /api/trips/trip_001/gps                 │
│ {latitude: 6.0329, longitude: 80.2168,      │
│  speed: 35}                                  │
└──────────────────────────────────────────────┘
         ↓
    ┌──────────────────────────────────────────┐
    │ BACKEND processes GPS:                   │
    │ • Stores in liveTrips collection         │
    │ • Stores in gpsHistory collection        │
    │ • Calculates distance to next stop       │
    │ • Calculates ETA (minutes + time)        │
    │ • Broadcasts via WebSocket               │
    └──────────────────────────────────────────┘
         ↓
    ┌──────────────────────────────────────────┐
    │ WebSocket Event: 'gps-update'            │
    │ {tripId, location, speed, eta,           │
    │  timestamp}                              │
    └──────────────────────────────────────────┘
         ↓
    ┌──────────────────────────────────────────┐
    │ PASSENGER APP receives update             │
    │ • Updates map marker position             │
    │ • Updates ETA countdown                   │
    │ • Shows distance to next stop             │
    └──────────────────────────────────────────┘

TIME: 14:50 - Trip Ends
┌──────────────────────────────────┐
│ DRIVER clicks "End Trip"         │
│ POST /api/trips/trip_001/end     │
└──────────────────────────────────┘
         ↓
    ┌──────────────────────────────────────────┐
    │ BACKEND:                                 │
    │ • Marks trip as 'completed'              │
    │ • Archives to completedTrips collection  │
    │ • Awards 50 impact points to driver      │
    │ • Calculates analytics                   │
    │ • Broadcasts trip-ended event            │
    └──────────────────────────────────────────┘
```

---

### 3️⃣ CROWD INTELLIGENCE FLOW

```
┌──────────────────────────────────────┐
│ PASSENGER near bus submits           │
│ POST /api/reports/crowd              │
│ {tripId, crowdLevel: "standing",     │
│  userLocation}                       │
└──────────────────────────────────────┘
         ↓
    ┌────────────────────────────────────────────────┐
    │ BACKEND validation:                            │
    │ • Check user is within 500m of bus (GPS)       │
    │ • Store in crowdReports collection             │
    │ • Award 5 impact points                        │
    └────────────────────────────────────────────────┘
         ↓
    ┌────────────────────────────────────────────────┐
    │ AGGREGATION ALGORITHM:                         │
    │ • Last 20 reports for trip                     │
    │ • Conductor: 1 report = override               │
    │ • Passengers: 60% same level = consensus       │
    │ • Calculate final crowd level                  │
    └────────────────────────────────────────────────┘
         ↓
    ┌────────────────────────────────────────────────┐
    │ UPDATE liveTrips.crowdLevel                    │
    │ Example results:                               │
    │ • "available" - 0-40% reported full            │
    │ • "standing" - 40-70% reported full            │
    │ • "full" - 70%+ reported full                  │
    └────────────────────────────────────────────────┘
         ↓
    ┌────────────────────────────────────────────────┐
    │ WebSocket: 'crowd-update'                      │
    │ Broadcast to all subscribed passengers         │
    └────────────────────────────────────────────────┘
         ↓
    ┌────────────────────────────────────────────────┐
    │ ALL PASSENGERS see updated crowd level         │
    │ Help them decide:                              │
    │ • Wait for next bus?                           │
    │ • Take this crowded one?                       │
    │ • Use alternative route?                       │
    └────────────────────────────────────────────────┘
```

---

### 4️⃣ EMERGENCY ALERT FLOW

```
┌────────────────────────────────────┐
│ DRIVER: Bus breaks down at stop    │
│ POST /api/alerts/emergency         │
│ {tripId, alertType: "breakdown",   │
│  message: "Near Unawatuna",        │
│  location}                         │
└────────────────────────────────────┘
         ↓
    ┌──────────────────────────────────────────┐
    │ BACKEND:                                 │
    │ • Create emergencyAlerts doc             │
    │ • Mark liveTrip.emergencyAlertActive     │
    │ • Get route info + affected passengers   │
    └──────────────────────────────────────────┘
         ↓
    ┌──────────────────────────────────────────┐
    │ WebSocket: 'emergency-alert'             │
    │ Broadcast to EVERYONE on route:          │
    │ {alertId, tripId, routeName,             │
    │  alertType, message, location}           │
    └──────────────────────────────────────────┘
         ↓
    ┌──────────────────────────────────────────┐
    │ ALL PASSENGERS see ALERT:                │
    │ 🚨 BREAKDOWN ALERT                       │
    │    Route 502: Galle → Hapugala           │
    │    Location: Near Unawatuna              │
    │    Alternative routes: 503, 504          │
    └──────────────────────────────────────────┘
         ↓
    ┌──────────────────────────────────────────┐
    │ ADMIN dashboard shows alert              │
    │ Can acknowledge + resolve when fixed     │
    │ POST /api/alerts/alert_id/resolve        │
    └──────────────────────────────────────────┘
```

---

## 🗄️ FIRESTORE COLLECTIONS ARCHITECTURE

```
┌─────────────────────────────────────────────────────────┐
│                    FIRESTORE COLLECTIONS               │
└─────────────────────────────────────────────────────────┘

USERS (Authentication & Profile)
├── uid
├── email
├── role (passenger/driver/conductor/admin)
├── fullName
├── impactPoints
└── status

ROUTES (Static Route Information)
├── routeId
├── name
├── stops[] (with coordinates)
├── estimatedDurationMinutes
├── peakHours
└── status

LIVE TRIPS (Active, Real-time)
├── tripId
├── status: "active"
├── currentLocation (geopoint)
├── currentSpeed
├── crowdLevel
├── eta (next stop)
├── passengers[]
└── emergencyAlertActive

GPS HISTORY (Archival, Analytics)
├── tripId
├── location (geopoint)
├── speed
├── timestamp
└── [Large collection - good for analytics]

CROWD REPORTS (Validation & Aggregation)
├── tripId
├── userId
├── crowdLevel
├── timestamp
└── [Used to recalculate consensus]

EMERGENCY ALERTS (Active Incidents)
├── alertId
├── tripId
├── alertType
├── status: "active/resolved"
├── message
└── location

COMPLETED TRIPS (Archived)
├── tripId (original)
├── All trip data
├── actualDuration
├── completedAt
└── [Source for analytics]

ROUTE ANALYTICS (Aggregated Insights)
├── routeId
├── date
├── totalTrips
├── averageDuration
├── onTimeProbability
└── [Pre-calculated for performance]
```

---

## 🌐 API ENDPOINT ARCHITECTURE

```
┌────────────────────────────────────────────────────────┐
│                    API GATEWAY                         │
│         (Express.js + JWT + Rate Limiting)             │
└────────────────────────────────────────────────────────┘
         ↓
    ┌─────────────────────────────────────────────────┐
    │         ROUTE HANDLERS (22 Endpoints)           │
    ├─────────────────────────────────────────────────┤
    │ 1. Authentication (3)                           │
    │    → /api/auth/signup                           │
    │    → /api/auth/login                            │
    │    → /api/auth/logout                           │
    ├─────────────────────────────────────────────────┤
    │ 2. Routes (4)                                   │
    │    → GET /api/routes                            │
    │    → GET /api/routes/:id                        │
    │    → GET /api/routes/:id/active-trips           │
    │    → GET /api/routes/:id/insights               │
    ├─────────────────────────────────────────────────┤
    │ 3. Trips (4)                                    │
    │    → POST /api/trips/initialize                 │
    │    → POST /api/trips/:id/gps                    │
    │    → GET /api/trips/:id                         │
    │    → POST /api/trips/:id/end                    │
    ├─────────────────────────────────────────────────┤
    │ 4. Crowd Reports (2)                            │
    │    → POST /api/reports/crowd                    │
    │    → GET /api/trips/:id/crowd-reports           │
    ├─────────────────────────────────────────────────┤
    │ 5. Emergency Alerts (2)                         │
    │    → POST /api/alerts/emergency                 │
    │    → POST /api/alerts/:id/resolve               │
    ├─────────────────────────────────────────────────┤
    │ 6. Admin (2)                                    │
    │    → GET /api/admin/dashboard                   │
    │    → GET /api/admin/analytics/routes            │
    ├─────────────────────────────────────────────────┤
    │ 7. User (2)                                     │
    │    → GET /api/users/:id                         │
    │    → PUT /api/users/:id/profile                 │
    ├─────────────────────────────────────────────────┤
    │ 8. Health (2)                                   │
    │    → GET /api/health                            │
    │    → GET /api/status                            │
    ├─────────────────────────────────────────────────┤
    │ 9. Search (1)                                   │
    │    → POST /api/search/routes                    │
    └─────────────────────────────────────────────────┘
         ↓
    ┌─────────────────────────────────────────────────┐
    │         FIRESTORE DATABASE LAYER                │
    │    (Real-time reads/writes + transactions)      │
    └─────────────────────────────────────────────────┘
```

---

## 📡 WEBSOCKET (REAL-TIME) ARCHITECTURE

```
┌─────────────────────────────────────────────────────┐
│         WEBSOCKET SERVER (Socket.io)                │
│              PORT 5000                              │
└─────────────────────────────────────────────────────┘
         ↓
    EVENTS (Server → Clients):
    ├─ 'gps-update' - Broadcast GPS to subscribers
    │  {tripId, location, speed, eta, timestamp}
    │
    ├─ 'crowd-update' - Broadcast crowd change
    │  {tripId, crowdLevel, reportedBy, timestamp}
    │
    ├─ 'emergency-alert' - Broadcast emergency
    │  {alertId, tripId, alertType, message, location}
    │
    ├─ 'eta-update' - Broadcast ETA change
    │  {tripId, eta, timestamp}
    │
    ├─ 'alert-resolved' - Alert cleared
    │  {alertId, tripId, timestamp}
    │
    ├─ 'trip-started' - New trip active
    │  {tripId, routeId, driverId, timestamp}
    │
    └─ 'trip-ended' - Trip completed
       {tripId, endTime, timestamp}

CLIENT ACTIONS:
    ├─ 'subscribe-trip' - Listen to trip updates
    │  socket.emit('subscribe-trip', 'trip_001')
    │
    ├─ 'subscribe-route' - Listen to route updates
    │  socket.emit('subscribe-route', 'route_502')
    │
    ├─ 'send-gps' - Send GPS (if driver)
    │  socket.emit('send-gps', {tripId, lat, lon})
    │
    └─ 'disconnect' - Client disconnected
       socket.on('disconnect', ...)
```

---

## 🔐 SECURITY LAYERS

```
┌────────────────────────────────────────────────────┐
│                SECURITY ARCHITECTURE               │
└────────────────────────────────────────────────────┘

LAYER 1: AUTHENTICATION
├─ Firebase Auth (email/password)
├─ JWT tokens (7-day expiry)
└─ Token verification middleware

LAYER 2: AUTHORIZATION
├─ Role-based access control
├─ User ID verification
├─ Admin-only endpoints
└─ Trip-specific permissions

LAYER 3: DATA VALIDATION
├─ Input sanitization
├─ GPS proximity checks (500m)
├─ Rate limiting (GPS: 5-10 sec intervals)
└─ Type checking

LAYER 4: FIRESTORE RULES
├─ Document-level security
├─ Collection-level access
├─ Role-based queries
└─ Write restrictions

LAYER 5: NETWORK SECURITY
├─ HTTPS (production)
├─ CORS configuration
├─ Rate limiting per IP
└─ WebSocket secure (WSS)
```

---

## 📊 PERFORMANCE OPTIMIZATION

```
CACHING LAYER
├─ Route data (static, rarely changes)
├─ Stop coordinates (cached on client)
├─ User profiles (cached after login)
└─ Analytics (pre-calculated daily)

DATABASE OPTIMIZATION
├─ Firestore indexes (composites)
├─ GPS history cleanup (30 days)
├─ Completed trip archive (90 days)
└─ Query limits (MAX 50 results)

REAL-TIME OPTIMIZATION
├─ GPS updates: 5-10 sec intervals
├─ Crowd aggregation: 200ms
├─ ETA calculation: 100ms
├─ WebSocket broadcast: <100ms
└─ Firestore listeners: on-demand

BANDWIDTH OPTIMIZATION
├─ JSON response compression
├─ Minimal field transmission
├─ Lazy loading (pagination)
└─ Delta updates (only changes)
```

---

## 🚀 DEPLOYMENT ARCHITECTURE

```
DEVELOPMENT
├─ Local Node.js server
├─ Local Firestore emulator (optional)
├─ Flutter debug build
└─ Hot reload enabled

STAGING
├─ Firebase Hosting (backend)
├─ Firestore (production-like)
├─ Flutter TestFlight/Beta
└─ Full feature testing

PRODUCTION
├─ Backend: Heroku/Railway/AWS
├─ Database: Firebase (auto-scaling)
├─ Frontend: App Store/Play Store
├─ CDN: Firebase Hosting
└─ Monitoring: Firebase Analytics + Custom logs
```

---

## 💾 DATA LIFECYCLE

```
USER DATA FLOW
└─ Signup
   └─ Stored in Firestore users collection
   └─ Encrypted password via Firebase Auth
   └─ JWT token generated
   └─ Profile accessible via API

TRIP DATA FLOW
└─ Initialize trip
   └─ Stored in liveTrips (active)
   └─ GPS updates stream continuously
   └─ Stored in gpsHistory (archive)
   └─ Crowd reports aggregated
   └─ Trip completed
   └─ Archived to completedTrips
   └─ Analytics calculated
   └─ Data available for reporting

ANALYTICS DATA FLOW
└─ Completed trips collected
   └─ Trip duration calculated
   └─ On-time status determined
   └─ Crowd distribution analyzed
   └─ RouteAnalytics updated
   └─ Admin dashboard updated
   └─ Insights available
```

---

## 🎯 SYSTEM QUALITY ATTRIBUTES

```
AVAILABILITY: 99.9% (Firebase SLA)
├─ Auto-failover
├─ Geographic redundancy
└─ Real-time database

SCALABILITY: Auto-scaling
├─ Firestore scales to millions
├─ WebSocket supports 10k+ connections
├─ Backend stateless (can scale horizontally)
└─ CDN for static assets

PERFORMANCE
├─ GPS update latency: <500ms
├─ ETA calculation: <100ms
├─ API response: <1sec
└─ WebSocket delivery: <100ms

SECURITY
├─ End-to-end encryption (HTTPS)
├─ Role-based access control
├─ Rate limiting
└─ Input validation

RELIABILITY
├─ Error handling on all endpoints
├─ Automatic retry on network failure
├─ Data backup (Firebase)
└─ Audit logging
```

---

**Architecture Status**: ✅ **PRODUCTION-READY**

🚀 Designed for scale, security, and real-time performance!
