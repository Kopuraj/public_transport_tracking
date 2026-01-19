# 🚀 TransitLive Pro - Quick Start Guide

## Get Your Backend Running in 5 Minutes

### ✅ Checklist

- [ ] Node.js 14+ installed
- [ ] Firebase project created
- [ ] Firebase Admin SDK key downloaded
- [ ] Backend folder ready

### 🎯 Step-by-Step

#### 1. Prepare Firebase (2 minutes)

```bash
# Go to https://console.firebase.google.com/
# 1. Create new project or use existing
# 2. Go to Settings → Service Accounts
# 3. Click "Generate new private key"
# 4. Save file as: backend/firebase-key.json
# 5. Copy Database URL from Firestore
```

#### 2. Setup Backend (2 minutes)

```bash
# Open PowerShell/Terminal
cd d:\5th semester\Mobile Application\transfort_tracker\backend

# Install packages
npm install

# Update .env file
# Open backend/.env and add:
# FIREBASE_DB_URL=https://your-project.firebaseio.com
```

#### 3. Start Backend (1 minute)

```bash
npm run dev

# Should see:
# ╔════════════════════════════════════════╗
# ║   TransitLive Pro Backend Running      ║
# ║   🚀 Server: http://localhost:5000     ║
# ║   📊 Firebase: Connected               ║
# ╚════════════════════════════════════════╝
```

#### 4. Test Frontend Connection

```bash
# New terminal/PowerShell
cd d:\5th semester\Mobile Application\transfort_tracker\public_transport_tracker
flutter pub get
flutter run -d windows
```

In the app:
1. Click "Check Backend Connection"
2. All tests should pass ✅

---

## 🚦 API Endpoints Ready to Use

### Sign Up
```
POST http://localhost:5000/api/auth/signup
Body: {email, password, fullName, role}
Response: {success, user, token}
```

### Login
```
POST http://localhost:5000/api/auth/login
Body: {email, password}
Response: {success, user, token}
```

### Initialize Trip
```
POST http://localhost:5000/api/trips/initialize
Headers: Authorization: Bearer {token}
Body: {driverId, vehicleId, routeId}
Response: {success, tripId}
```

### Send GPS
```
POST http://localhost:5000/api/trips/{tripId}/gps
Headers: Authorization: Bearer {token}
Body: {latitude, longitude, speed}
Response: {success}
```

### Get Trip Details
```
GET http://localhost:5000/api/trips/{tripId}
Response: {success, trip}
```

### Submit Crowd Report
```
POST http://localhost:5000/api/reports/crowd
Headers: Authorization: Bearer {token}
Body: {tripId, crowdLevel, location}
Response: {success, aggregatedSentiment}
```

### Emergency Alert
```
POST http://localhost:5000/api/alerts/emergency
Headers: Authorization: Bearer {token}
Body: {tripId, alertType, description}
Response: {success}
```

### End Trip
```
POST http://localhost:5000/api/trips/{tripId}/end
Headers: Authorization: Bearer {token}
Response: {success}
```

### Health Check
```
GET http://localhost:5000/api/health
Response: {status: ok}
```

---

## 💻 Frontend Usage

### Use Real Backend in Your Code

Replace mock calls with real API:

```dart
// Import the API service
import 'package:public_transport_tracker/services/api_service.dart';

final apiService = ApiService();

// Sign Up
try {
  final result = await apiService.signUp(
    email: 'user@example.com',
    password: 'password123',
    fullName: 'John Doe',
    role: 'driver'
  );
  print('✅ ${result['user']['fullName']} signed up!');
} catch (e) {
  print('❌ Error: $e');
}

// Login
try {
  final result = await apiService.login(
    email: 'user@example.com',
    password: 'password123'
  );
  print('✅ Logged in!');
} catch (e) {
  print('❌ Error: $e');
}

// Initialize Trip
try {
  final result = await apiService.initializeTrip(
    driverId: 'driver123',
    vehicleId: 'BUS-502',
    routeId: 'route502'
  );
  final tripId = result['tripId'];
  print('✅ Trip started: $tripId');
} catch (e) {
  print('❌ Error: $e');
}

// Send GPS (continuous loop)
void _streamGPS(String tripId) {
  // Call every 5-10 seconds
  apiService.sendGpsUpdate(
    tripId: tripId,
    latitude: 6.0357,
    longitude: 80.2127,
    speed: 45
  );
}

// Get Trip Details
try {
  final result = await apiService.getTripDetails(tripId);
  final trip = result['trip'];
  print('📍 Bus at: ${trip['currentLocation']}');
  print('👥 Occupancy: ${trip['occupancy']}');
  print('😊 Crowd: ${trip['crowdLevel']}');
} catch (e) {
  print('❌ Error: $e');
}

// Submit Crowd Report
try {
  final result = await apiService.submitCrowdReport(
    tripId: tripId,
    crowdLevel: 'high',
    latitude: 6.0357,
    longitude: 80.2127
  );
  print('✅ Report submitted');
  print('📊 Aggregated: ${result['aggregatedSentiment']}');
} catch (e) {
  print('❌ Error: $e');
}

// End Trip
try {
  final result = await apiService.endTrip(tripId);
  print('✅ ${result['message']}');
} catch (e) {
  print('❌ Error: $e');
}
```

---

## 🔌 Real-time WebSocket (Advanced)

Add to your dependencies in `pubspec.yaml`:
```yaml
socket_io_client: ^1.0.1
```

Listen to real-time updates:
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

void _setupWebSocket() {
  final socket = IO.io(
    'http://localhost:5000',
    IO.OptionBuilder().setTransports(['websocket']).build()
  );

  socket.onConnect((_) {
    print('✅ WebSocket connected');
    socket.emit('subscribe-trip', tripId);
  });

  socket.on('gps-update', (data) {
    print('📍 New GPS: ${data['location']}');
    _updateMapMarker(data['location']);
  });

  socket.on('crowd-update', (data) {
    print('👥 Crowd: ${data['crowdLevel']}');
    setState(() { crowdLevel = data['crowdLevel']; });
  });

  socket.on('eta-update', (data) {
    print('⏱️ ETAs updated');
    _updateETAList(data['etaData']);
  });

  socket.on('emergency-alert', (data) {
    print('🚨 ${data['alertType']}');
    _showEmergencyNotification(data);
  });

  socket.onDisconnect((_) => print('❌ WebSocket disconnected'));
}
```

---

## 🧪 Manual API Testing

Test endpoints directly with PowerShell:

### Sign Up
```powershell
$body = @{
  email = "driver@galle.com"
  password = "pass123"
  fullName = "John Doe"
  role = "driver"
} | ConvertTo-Json

Invoke-WebRequest -Uri http://localhost:5000/api/auth/signup `
  -Method POST `
  -ContentType "application/json" `
  -Body $body
```

### Login
```powershell
$body = @{
  email = "driver@galle.com"
  password = "pass123"
} | ConvertTo-Json

$response = Invoke-WebRequest -Uri http://localhost:5000/api/auth/login `
  -Method POST `
  -ContentType "application/json" `
  -Body $body

$token = ($response.Content | ConvertFrom-Json).token
Write-Host "Token: $token"
```

### Initialize Trip (with token)
```powershell
$token = "YOUR_TOKEN_HERE"
$body = @{
  driverId = "driver123"
  vehicleId = "BUS-502"
  routeId = "route502"
} | ConvertTo-Json

Invoke-WebRequest -Uri http://localhost:5000/api/trips/initialize `
  -Method POST `
  -ContentType "application/json" `
  -Headers @{ Authorization = "Bearer $token" } `
  -Body $body
```

---

## 🐛 Troubleshooting

### Backend won't start
```bash
# Check if port 5000 is in use
netstat -ano | findstr :5000

# Kill the process
taskkill /PID <PID> /F

# Try again
npm run dev
```

### Firebase connection error
```
Error: ENOENT: no such file or directory, open 'firebase-key.json'
```
**Solution:** 
1. Download firebase-key.json from Firebase Console
2. Save to `backend/firebase-key.json`
3. Restart server

### Token errors
```
❌ No token provided
```
**Solution:** Log in first to get a token, then include in headers:
```
Authorization: Bearer YOUR_TOKEN_HERE
```

### CORS errors
Already configured in backend! No action needed.

### Slow responses
- Check internet connection
- Ensure Firebase Firestore is responsive
- Increase timeouts if needed

---

## ✅ Validation

Check if everything works:

```bash
# 1. Backend running?
curl http://localhost:5000/api/health
# Expected: {"status":"ok","message":"..."}

# 2. Can sign up?
# Use PowerShell example above

# 3. Can login?
# Use PowerShell example above

# 4. Frontend connected?
# In Flutter app, click "Check Backend Connection"
# All tests should pass ✅
```

---

## 📚 Files Created

```
backend/
├── server.js           ← Main backend server
├── package.json        ← Dependencies
├── .env                ← Configuration (KEEP SECRET!)
├── firebase-key.json   ← Firebase credentials (KEEP SECRET!)
├── .gitignore          ← Git ignore rules
└── README.md           ← Detailed docs

Frontend (updated)
├── lib/services/api_service.dart          ← API client (NEW)
├── lib/screens/backend_connectivity_checker.dart  ← Test tool
└── pubspec.yaml        ← Added dependencies
```

---

## 🎉 You're All Set!

**Your TransitLive Pro system is now:**
- ✅ Backend operational on localhost:5000
- ✅ Frontend connected to real backend
- ✅ Real-time capable
- ✅ Production-ready architecture

**Next:** Deploy to cloud for production! 🚀

---

## 📞 Quick Reference

| What | Command |
|------|---------|
| Start Backend | `cd backend && npm run dev` |
| Start Frontend | `flutter run -d windows` |
| Install deps | `npm install` (backend) or `flutter pub get` (frontend) |
| Health check | `curl http://localhost:5000/api/health` |
| View logs | Check console output |
| Stop server | `Ctrl+C` |
| Clear cache | `npm cache clean --force` |

**Everything is ready! Start building! 🚀**
