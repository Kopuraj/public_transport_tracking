# 🚀 5-MINUTE QUICK START GUIDE
## TransitLive Pro Backend - Get Running Now!

---

## ⚡ FASTEST PATH TO SUCCESS

### 1️⃣ Get Firebase Credentials (2 minutes)

```
1. Go to: https://console.firebase.google.com/
2. Create project: "TransitLive Pro"
3. Enable Firestore Database
4. Go to Settings → Service Accounts
5. Click "Generate new private key"
6. Save file as: backend/firebase-key.json
7. Copy "Database URL" from Firestore section
```

### 2️⃣ Create `.env` File (1 minute)

In `backend/.env`:
```
PORT=5000
NODE_ENV=development
FIREBASE_DB_URL=https://YOUR-PROJECT.firebaseio.com
FIREBASE_WEB_API_KEY=YOUR_WEB_API_KEY
JWT_SECRET=super-secret-change-in-production
```

**Get FIREBASE_WEB_API_KEY:**
- Firebase Console → Project Settings → Web API Key

### 3️⃣ Install & Start (2 minutes)

```bash
cd backend
npm install
npm run dev
```

**Expected output:**
```
✅ TransitLive Pro Backend Started
   Server: http://localhost:5000
   WebSocket: ws://localhost:5000
   Firebase: Connected & Ready
```

### ✅ DONE! Backend is running!

---

## 🧪 QUICK TEST

Open PowerShell and run:

```powershell
# Test 1: Health Check
curl http://localhost:5000/api/health

# Test 2: Create User
$body = @{
    email = "test@example.com"
    password = "password123"
    fullName = "Test User"
    role = "passenger"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/api/auth/signup" `
  -Method Post `
  -ContentType "application/json" `
  -Body $body
```

---

## 📱 TEST WITH FLUTTER APP

```bash
cd public_transport_tracker
flutter pub get
flutter run -d windows
```

In app: Click "Test Screens" → "Backend Connectivity Checker" → All tests should ✅

---

## 🎯 Main Features Working

✅ User Authentication (Signup/Login)  
✅ Real-time GPS Tracking  
✅ Crowd Intelligence System  
✅ Emergency Alerts  
✅ Route Management  
✅ Trip Analytics  
✅ Admin Dashboard  
✅ WebSocket Real-time Updates  

---

## 📡 API QUICK REFERENCE

| Action | Method | Endpoint |
|--------|--------|----------|
| Login | POST | `/api/auth/login` |
| Get Routes | GET | `/api/routes` |
| Start Trip | POST | `/api/trips/initialize` |
| Send GPS | POST | `/api/trips/{tripId}/gps` |
| Report Crowd | POST | `/api/reports/crowd` |
| Emergency Alert | POST | `/api/alerts/emergency` |
| Health Check | GET | `/api/health` |

---

## 🔑 AUTHENTICATION

After login, you get a token:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

Use in all requests:
```
Authorization: Bearer {token}
```

---

## 🐛 COMMON ISSUES & FIXES

### Issue: "Port 5000 already in use"
```bash
# Kill existing process
netstat -ano | findstr :5000
taskkill /PID <PID> /F
npm run dev
```

### Issue: "firebase-key.json not found"
```
1. Download from Firebase Console
2. Save as: backend/firebase-key.json
3. Check file exists before running
```

### Issue: "FIREBASE_DB_URL not set"
```
1. Go to Firebase Console → Firestore
2. Copy Database URL
3. Add to .env file
4. Restart backend
```

### Issue: "App can't connect to backend"
```
1. Backend must be running: npm run dev
2. Check localhost:5000/api/health
3. For Android: Use device IP instead of localhost
4. Check firewall allows port 5000
```

---

## 🌐 REAL-TIME FEATURES

### WebSocket Events Automatically Streaming:

```
✅ GPS Updates (every 5-10 sec)
✅ Crowd Level Changes (instant)
✅ Emergency Alerts (instant)
✅ ETA Recalculation (real-time)
```

No additional setup needed - all built in!

---

## 📊 DATABASE COLLECTIONS

Automatically created by backend:

```
✅ users - User profiles
✅ routes - Transport routes
✅ liveTrips - Active trips
✅ crowdReports - Crowd data
✅ emergencyAlerts - Alerts
✅ completedTrips - Archives
✅ gpsHistory - GPS logs
✅ And more...
```

---

## 🎓 UNDERSTANDING THE FLOW

```
1. Passenger opens app
   → Logs in → Gets JWT token

2. Passenger searches routes
   → GET /api/search/routes

3. Passenger sees active buses
   → WebSocket subscribes to trip updates

4. Driver GPS streams in
   → POST /api/trips/{tripId}/gps

5. Backend broadcasts to passengers
   → WebSocket: 'gps-update' event

6. Passenger sees live location & ETA
   → Updates in real-time

7. Passenger reports crowd
   → POST /api/reports/crowd

8. All passengers see updated crowd level
   → WebSocket: 'crowd-update' event
```

---

## 🚀 DEPLOYMENT PREVIEW

When ready for production:

```bash
# 1. Deploy backend (Heroku/Railway/AWS)
# 2. Update API URL in Flutter app
# 3. Enable HTTPS
# 4. Configure production Firebase rules
# 5. Deploy Flutter to Play Store/App Store
```

---

## ✅ YOUR CHECKLIST

- [ ] Firebase project created
- [ ] Private key downloaded (firebase-key.json)
- [ ] .env file configured
- [ ] Backend running (npm run dev)
- [ ] Health check passing
- [ ] Can signup/login
- [ ] Flutter app connecting
- [ ] Backend connectivity test passing

---

## 🎉 YOU'RE READY!

Your backend is:
✨ Running  
✨ Connected to Firebase  
✨ Ready for real-time updates  
✨ Production-ready  

**Next: Test all features with your Flutter app!**

---

## 📞 QUICK HELP

**Backend Won't Run:**
→ Check Node.js installed: `node --version`  
→ Check firebase-key.json exists  
→ Check .env file configured  

**Can't Connect from App:**
→ Ensure backend is running  
→ Check http://localhost:5000/api/health  
→ For real device: use IP instead of localhost  

**Firebase Error:**
→ Verify Database URL in .env  
→ Check Firestore is enabled in Firebase  
→ Verify firestore rules are published  

---

**Status: ✅ READY TO GO!**

🚀 Start with `npm run dev` and test with Flutter! 🎉
