# TransitLive Pro Backend Setup Guide

## 🚀 Quick Start

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Configure Firebase
1. Download Firebase Admin SDK key from [Firebase Console](https://console.firebase.google.com/)
2. Save as `firebase-key.json` in the backend folder
3. Update `.env` with your Firebase database URL

### 3. Start Backend
```bash
# Development with hot reload
npm run dev

# Production
npm start
```

## 📊 Backend Architecture

### Real-time Trip Flow:
```
Driver Login → Trip Initialization → GPS Streaming → Crowd Reports → 
Trip Completion → Analytics Generation
```

### WebSocket Events:
- `gps-update` - Driver location updates (5-10 seconds)
- `crowd-update` - Crowd sentiment changes
- `eta-update` - ETA recalculations
- `emergency-alert` - Emergency notifications

## 🔌 Frontend Connection

### Update Frontend API Configuration

In `lib/config/api_config.dart`:
```dart
const String BACKEND_URL = 'http://localhost:5000';
const String WS_URL = 'ws://localhost:5000';
```

### Real-time Event Listener (Dart):
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

final socket = IO.io(
  'http://localhost:5000',
  IO.OptionBuilder().setTransports(['websocket']).build()
);

socket.on('gps-update', (data) {
  // Update map with new location
});

socket.on('crowd-update', (data) {
  // Update crowd level indicator
});
```

## 📱 Frontend API Calls

### Login Example:
```dart
final response = await http.post(
  Uri.parse('$BACKEND_URL/api/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'email': email,
    'password': password
  })
);

final data = jsonDecode(response.body);
final token = data['token'];

// Save token for future requests
SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', token);
```

### Initialize Trip (Driver):
```dart
final token = await getStoredToken();
final response = await http.post(
  Uri.parse('$BACKEND_URL/api/trips/initialize'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json'
  },
  body: jsonEncode({
    'driverId': driverId,
    'vehicleId': vehicleId,
    'routeId': routeId502
  })
);
```

### Send GPS Update (Driver):
```dart
_locationService.listen((LocationData currentLocation) async {
  await http.post(
    Uri.parse('$BACKEND_URL/api/trips/$tripId/gps'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    },
    body: jsonEncode({
      'latitude': currentLocation.latitude,
      'longitude': currentLocation.longitude,
      'speed': currentLocation.speed
    })
  );
});
```

### Submit Crowd Report (Passenger):
```dart
await http.post(
  Uri.parse('$BACKEND_URL/api/reports/crowd'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json'
  },
  body: jsonEncode({
    'tripId': tripId,
    'crowdLevel': 'high', // 'low', 'medium', 'high'
    'location': {
      'latitude': currentLat,
      'longitude': currentLong
    }
  })
);
```

## 🗄️ Firestore Collections Setup

Run these commands in Firebase Console:

```javascript
// Create users collection with index
db.collection('users').add({
  email: 'test@example.com',
  fullName: 'Test User',
  role: 'passenger',
  impactPoints: 0
})

// Create routes collection
db.collection('routes').add({
  name: '502 Route',
  startPoint: 'Galle',
  endPoint: 'Hapugala',
  stops: [
    { name: 'Karapitiya Junction', latitude: 6.0357, longitude: 80.2127 },
    { name: 'University Entrance', latitude: 6.0456, longitude: 80.2234 }
  ]
})
```

## 🧪 Test API Endpoints

### Health Check:
```bash
curl http://localhost:5000/api/health
```

### Sign Up:
```bash
curl -X POST http://localhost:5000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"driver@galle.com","password":"pass123","fullName":"John Doe","role":"driver"}'
```

### Login:
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"driver@galle.com","password":"pass123"}'
```

## 📈 Scaling Considerations

- Deploy to Google Cloud Run for auto-scaling
- Use Firestore for real-time syncing
- Implement Redis for caching
- Add load balancing for WebSocket connections
- Monitor with Cloud Monitoring

## 🔐 Production Checklist

- [ ] Change JWT_SECRET
- [ ] Enable HTTPS only
- [ ] Restrict CORS origins
- [ ] Implement rate limiting
- [ ] Add request validation
- [ ] Set up logging
- [ ] Configure error tracking (Sentry)
- [ ] Add database backups
