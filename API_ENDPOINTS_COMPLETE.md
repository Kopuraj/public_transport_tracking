# 📡 Complete API Endpoint Reference
## TransitLive Pro Backend - All Endpoints

---

## 🔐 Authentication Endpoints

### 1. Sign Up
Create a new user account

```
POST /api/auth/signup
Content-Type: application/json

Request Body:
{
  "email": "driver@example.com",
  "password": "password123",
  "fullName": "John Driver",
  "role": "driver",           // "passenger", "driver", "conductor", "admin"
  "phone": "+94771234567",    // optional
  "vehicle": {                // optional, for drivers
    "licenseNumber": "DL-2024-001",
    "vehicleId": "bus_502"
  }
}

Success Response (200):
{
  "success": true,
  "user": {
    "uid": "user_123",
    "email": "driver@example.com",
    "fullName": "John Driver",
    "role": "driver"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}

Error Response (400):
{
  "success": false,
  "error": "Email already registered"
}
```

### 2. Login
Authenticate user and get JWT token

```
POST /api/auth/login
Content-Type: application/json

Request Body:
{
  "email": "driver@example.com",
  "password": "password123"
}

Success Response (200):
{
  "success": true,
  "user": {
    "uid": "user_123",
    "email": "driver@example.com",
    "fullName": "John Driver",
    "role": "driver",
    "impactPoints": 150
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}

Error Response (401):
{
  "success": false,
  "error": "Invalid email or password"
}
```

### 3. Logout
Logout user (optional - tokens expire automatically)

```
POST /api/auth/logout
Authorization: Bearer {token}

Success Response (200):
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

## 🚌 Routes Endpoints

### 4. Get All Routes
Retrieve list of all available routes

```
GET /api/routes

Success Response (200):
{
  "success": true,
  "routes": [
    {
      "id": "route_502",
      "name": "502: Galle → Hapugala",
      "routeNumber": "502",
      "vehicleType": "bus",
      "stops": [
        {
          "id": "stop_galle",
          "name": "Galle",
          "latitude": 6.0329,
          "longitude": 80.2168,
          "sequence": 1
        }
      ],
      "estimatedDurationMinutes": 45,
      "peakHours": ["07:00-09:00", "17:00-19:00"],
      "status": "active"
    }
  ]
}
```

### 5. Get Specific Route
Get details of a specific route

```
GET /api/routes/:routeId

Example: GET /api/routes/route_502

Success Response (200):
{
  "success": true,
  "route": {
    "id": "route_502",
    "name": "502: Galle → Hapugala",
    "routeNumber": "502",
    "vehicleType": "bus",
    "stops": [...],
    "estimatedDurationMinutes": 45,
    "status": "active"
  }
}

Error Response (404):
{
  "success": false,
  "error": "Route not found"
}
```

### 6. Get Active Trips on Route
Get currently active trips on a specific route

```
GET /api/routes/:routeId/active-trips

Example: GET /api/routes/route_502/active-trips

Success Response (200):
{
  "success": true,
  "trips": [
    {
      "id": "trip_001",
      "routeId": "route_502",
      "driverId": "driver_123",
      "currentLocation": {
        "latitude": 6.0300,
        "longitude": 80.2200
      },
      "crowdLevel": "standing",
      "eta": {
        "nextStopName": "Unawatuna",
        "etaMinutes": 8
      }
    }
  ]
}
```

### 7. Get Route Insights
Get analytics and insights for a route (last 7 days)

```
GET /api/routes/:routeId/insights

Example: GET /api/routes/route_502/insights

Success Response (200):
{
  "success": true,
  "insights": {
    "routeName": "502: Galle → Hapugala",
    "totalTripsLastWeek": 42,
    "averageDurationMinutes": 48,
    "onTimeProbability": 85,
    "crowdDistribution": {
      "available": 10,
      "standing": 20,
      "full": 12
    },
    "peakHours": "07:00-09:00, 17:00-19:00",
    "averagePassengers": 52
  }
}
```

---

## 🚕 Trip Management Endpoints

### 8. Initialize Trip (Driver)
Start a new trip/duty

```
POST /api/trips/initialize
Authorization: Bearer {token}
Content-Type: application/json

Request Body:
{
  "vehicleId": "bus_502",
  "routeId": "route_502",
  "conductorId": "conductor_123"  // optional
}

Success Response (200):
{
  "success": true,
  "tripId": "trip_20240203_001",
  "message": "Trip duty started successfully",
  "route": {
    "name": "502: Galle → Hapugala",
    "stops": [...]
  }
}

Error Response (401):
{
  "success": false,
  "error": "Only drivers can initialize trips"
}
```

### 9. Send GPS Update
Send real-time GPS location (driver sends continuously)

```
POST /api/trips/:tripId/gps
Authorization: Bearer {token}
Content-Type: application/json

Example: POST /api/trips/trip_001/gps

Request Body:
{
  "latitude": 6.0329,
  "longitude": 80.2168,
  "speed": 35,           // km/h, optional
  "accuracy": 10         // meters, optional
}

Success Response (200):
{
  "success": true,
  "message": "GPS data received",
  "eta": {
    "nextStopName": "Unawatuna",
    "nextStopId": "stop_unawatuna",
    "distanceKm": 3.2,
    "etaMinutes": 8,
    "estimatedArrivalTime": "2024-02-03T14:35:00Z"
  }
}

Broadcast Event (WebSocket):
{
  "event": "gps-update",
  "data": {
    "tripId": "trip_001",
    "location": { "latitude": 6.0329, "longitude": 80.2168 },
    "speed": 35,
    "eta": { "etaMinutes": 8 },
    "timestamp": "2024-02-03T14:27:00Z"
  }
}
```

### 10. Get Trip Details
Get current details of a trip

```
GET /api/trips/:tripId

Example: GET /api/trips/trip_001

Success Response (200):
{
  "success": true,
  "trip": {
    "id": "trip_001",
    "driverId": "driver_123",
    "vehicleId": "bus_502",
    "routeId": "route_502",
    "status": "active",
    "startTime": "2024-02-03T07:00:00Z",
    "currentLocation": {
      "latitude": 6.0329,
      "longitude": 80.2168
    },
    "currentSpeed": 35,
    "occupancy": 42,
    "crowdLevel": "standing",
    "eta": {
      "nextStopName": "Unawatuna",
      "etaMinutes": 8
    },
    "route": { "name": "502: Galle → Hapugala" },
    "driver": { "fullName": "John Driver" }
  }
}
```

### 11. End Trip (Driver)
Complete/end a trip

```
POST /api/trips/:tripId/end
Authorization: Bearer {token}
Content-Type: application/json

Example: POST /api/trips/trip_001/end

Success Response (200):
{
  "success": true,
  "message": "Trip ended successfully",
  "impactPointsAwarded": 50
}

Broadcast Event (WebSocket):
{
  "event": "trip-ended",
  "data": {
    "tripId": "trip_001",
    "endTime": "2024-02-03T14:50:00Z"
  }
}
```

---

## 👥 Crowd Intelligence Endpoints

### 12. Submit Crowd Report
Report current crowd level in vehicle

```
POST /api/reports/crowd
Authorization: Bearer {token}
Content-Type: application/json

Request Body:
{
  "tripId": "trip_001",
  "crowdLevel": "standing",    // "available", "standing", "full"
  "userLocation": {
    "latitude": 6.0329,
    "longitude": 80.2168
  }
}

Success Response (200):
{
  "success": true,
  "message": "Crowd report submitted",
  "crowdLevel": "standing",
  "impactPointsAwarded": 5
}

Error Response (400):
{
  "success": false,
  "error": "You are too far from the bus to report"
}

Broadcast Event (WebSocket):
{
  "event": "crowd-update",
  "data": {
    "tripId": "trip_001",
    "crowdLevel": "standing",
    "reportedBy": "passenger",
    "timestamp": "2024-02-03T14:27:30Z"
  }
}
```

### 13. Get Crowd Reports for Trip
Get all crowd reports for a specific trip

```
GET /api/trips/:tripId/crowd-reports

Example: GET /api/trips/trip_001/crowd-reports

Success Response (200):
{
  "success": true,
  "reports": [
    {
      "id": "report_123",
      "tripId": "trip_001",
      "userId": "user_456",
      "userRole": "passenger",
      "crowdLevel": "standing",
      "location": {
        "latitude": 6.0329,
        "longitude": 80.2168
      },
      "timestamp": "2024-02-03T14:27:30Z"
    },
    {
      "id": "report_124",
      "tripId": "trip_001",
      "userId": "user_conductor",
      "userRole": "conductor",
      "crowdLevel": "full",
      "timestamp": "2024-02-03T14:28:00Z"
    }
  ]
}
```

---

## 🚨 Emergency Alert Endpoints

### 14. Send Emergency Alert
Broadcast emergency alert to passengers

```
POST /api/alerts/emergency
Authorization: Bearer {token}
Content-Type: application/json

Request Body:
{
  "tripId": "trip_001",
  "alertType": "breakdown",     // "breakdown", "accident", "medical", "security", "traffic"
  "message": "Bus breakdown near Unawatuna. Alternative route suggested.",
  "location": {
    "latitude": 6.0256,
    "longitude": 80.2606
  }
}

Success Response (200):
{
  "success": true,
  "alertId": "alert_789",
  "message": "Emergency alert broadcast to passengers"
}

Broadcast Event (WebSocket):
{
  "event": "emergency-alert",
  "data": {
    "alertId": "alert_789",
    "tripId": "trip_001",
    "routeId": "route_502",
    "routeName": "502: Galle → Hapugala",
    "alertType": "breakdown",
    "message": "Bus breakdown near Unawatuna",
    "location": {
      "latitude": 6.0256,
      "longitude": 80.2606
    },
    "timestamp": "2024-02-03T14:30:00Z"
  }
}
```

### 15. Resolve Emergency Alert
Mark emergency alert as resolved

```
POST /api/alerts/:alertId/resolve
Authorization: Bearer {token}
Content-Type: application/json

Example: POST /api/alerts/alert_789/resolve

Success Response (200):
{
  "success": true,
  "message": "Alert resolved"
}

Broadcast Event (WebSocket):
{
  "event": "alert-resolved",
  "data": {
    "alertId": "alert_789",
    "tripId": "trip_001",
    "timestamp": "2024-02-03T14:40:00Z"
  }
}
```

---

## 🔍 Search & Analytics Endpoints

### 16. Search Routes
Find routes between two stops

```
POST /api/search/routes
Content-Type: application/json

Request Body:
{
  "startStop": "Galle",
  "endStop": "Hapugala"
}

Success Response (200):
{
  "success": true,
  "results": [
    {
      "route": {
        "id": "route_502",
        "name": "502: Galle → Hapugala",
        "stops": [...]
      },
      "activeTrips": [
        {
          "id": "trip_001",
          "crowdLevel": "standing",
          "eta": { "etaMinutes": 8 }
        }
      ]
    }
  ]
}
```

---

## 👤 User Profile Endpoints

### 17. Get User Profile
Get user's profile information

```
GET /api/users/:userId
Authorization: Bearer {token}

Example: GET /api/users/user_123

Success Response (200):
{
  "success": true,
  "user": {
    "id": "user_123",
    "uid": "user_123",
    "email": "driver@example.com",
    "fullName": "John Driver",
    "role": "driver",
    "phone": "+94771234567",
    "impactPoints": 150,
    "createdAt": "2024-01-01T00:00:00Z",
    "status": "active"
  }
}
```

### 18. Update User Profile
Update profile information

```
PUT /api/users/:userId/profile
Authorization: Bearer {token}
Content-Type: application/json

Request Body:
{
  "fullName": "John Smith",
  "phone": "+94771234568",
  "preferences": {
    "notifications": true,
    "darkMode": false,
    "language": "en"
  }
}

Success Response (200):
{
  "success": true,
  "message": "Profile updated"
}
```

---

## 👨‍💼 Admin Endpoints

### 19. Get Admin Dashboard
Get real-time system overview (admin only)

```
GET /api/admin/dashboard
Authorization: Bearer {token}

Success Response (200):
{
  "success": true,
  "dashboard": {
    "activeTripsCount": 12,
    "completedTripsToday": 45,
    "emergencyAlertsToday": 3,
    "totalUsers": 250,
    "activeTrips": [
      {
        "id": "trip_001",
        "routeId": "route_502",
        "status": "active",
        "crowdLevel": "standing"
      }
    ]
  }
}

Error Response (401):
{
  "success": false,
  "error": "Admin access required"
}
```

### 20. Get Route Analytics
Get detailed analytics for all routes

```
GET /api/admin/analytics/routes
Authorization: Bearer {token}

Success Response (200):
{
  "success": true,
  "analytics": [
    {
      "routeId": "route_502",
      "routeName": "502: Galle → Hapugala",
      "tripsLastWeek": 42,
      "avgCrowdLevel": "medium"
    }
  ]
}
```

---

## 🏥 System Health Endpoints

### 21. Health Check
Check backend and Firebase connection status

```
GET /api/health

Success Response (200):
{
  "success": true,
  "status": "healthy",
  "server": "TransitLive Pro Backend",
  "timestamp": "2024-02-03T14:27:00Z",
  "firebaseConnected": true
}

Error Response (500):
{
  "success": false,
  "status": "unhealthy",
  "error": "Firebase connection failed"
}
```

### 22. Backend Status
Get detailed backend status

```
GET /api/status

Success Response (200):
{
  "success": true,
  "status": "running",
  "server": "TransitLive Pro Backend",
  "port": 5000,
  "environment": "development",
  "websocket": "connected",
  "timestamp": "2024-02-03T14:27:00Z"
}
```

---

## 🌐 WebSocket Events (Real-time)

### Client subscribes to trip:
```javascript
socket.emit('subscribe-trip', 'trip_001');
```

### Server broadcasts GPS update:
```javascript
io.emit('gps-update', {
  tripId: 'trip_001',
  location: { latitude: 6.0329, longitude: 80.2168 },
  speed: 35,
  eta: { etaMinutes: 8 },
  timestamp: new Date()
});
```

### Server broadcasts crowd update:
```javascript
io.emit('crowd-update', {
  tripId: 'trip_001',
  crowdLevel: 'standing',
  reportedBy: 'conductor',
  timestamp: new Date()
});
```

### Server broadcasts emergency alert:
```javascript
io.emit('emergency-alert', {
  alertId: 'alert_789',
  tripId: 'trip_001',
  alertType: 'breakdown',
  message: 'Bus breakdown near Unawatuna',
  timestamp: new Date()
});
```

---

## 📝 Response Status Codes

| Code | Status | Meaning |
|------|--------|---------|
| 200 | OK | Request successful |
| 400 | Bad Request | Invalid request parameters |
| 401 | Unauthorized | Authentication required or invalid |
| 404 | Not Found | Resource not found |
| 500 | Server Error | Internal server error |

---

## 🔑 Authentication

All protected endpoints require JWT token in header:

```
Authorization: Bearer {token}
```

Token expires in **7 days**. Get new token by logging in again.

---

## 📊 Sample Request/Response Flow

### 1. Passenger searches for routes:
```
POST /api/search/routes
→ Returns available routes and active trips

2. Passenger selects a trip:
GET /api/trips/{tripId}
→ Returns trip details (location, ETA, crowd level)

3. Passenger submits crowd report:
POST /api/reports/crowd
→ Updates crowd level in real-time

4. Passenger receives updates via WebSocket:
WebSocket: 'gps-update', 'crowd-update', 'emergency-alert'
```

---

## 🚀 Ready to Go Live!

All endpoints are production-ready with:
✅ Error handling
✅ Input validation
✅ Real-time updates
✅ Role-based access control
✅ Impact points system
✅ Analytics tracking

**Start your backend and connect your flutter app!** 🎉
