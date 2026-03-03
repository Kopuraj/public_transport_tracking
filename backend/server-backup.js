// TransitLive Pro Backend - Main Server
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const socketIO = require('socket.io');
const admin = require('firebase-admin');
const jwt = require('jsonwebtoken');

// Initialize Firebase
const serviceAccount = require('./firebase-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: process.env.FIREBASE_DB_URL
});

const db = admin.firestore();
const auth = admin.auth();

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// ============================================
// 1. AUTHENTICATION ENDPOINTS
// ============================================

app.post('/api/auth/signup', async (req, res) => {
  try {
    const { email, password, fullName, role } = req.body;

    // Validate input
    if (!email || !password || !fullName) {
      return res.status(400).json({ 
        success: false, 
        error: 'Missing required fields: email, password, fullName' 
      });
    }

    if (password.length < 6) {
      return res.status(400).json({ 
        success: false, 
        error: 'Password must be at least 6 characters' 
      });
    }

    // Check if user already exists
    const existingUser = await db.collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (!existingUser.empty) {
      return res.status(400).json({ 
        success: false, 
        error: 'Email already registered. Try logging in.' 
      });
    }

    // Create Firebase user
    const userRecord = await auth.createUser({
      email: email,
      password: password,
      displayName: fullName
    });

    // Store user data in Firestore
    await db.collection('users').doc(userRecord.uid).set({
      uid: userRecord.uid,
      email: email,
      fullName: fullName,
      role: role || 'passenger',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      impactPoints: 0,
      status: 'active'
    });

    // Generate JWT token
    if (!process.env.JWT_SECRET) {
      console.error('❌ JWT_SECRET not configured in .env file');
      return res.status(500).json({ 
        success: false, 
        error: 'Server configuration error' 
      });
    }

    const token = jwt.sign(
      { uid: userRecord.uid, email: email },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    console.log(`✅ Signup successful: ${email}`);

    res.status(200).json({
      success: true,
      user: {
        uid: userRecord.uid,
        email: email,
        fullName: fullName,
        role: role || 'passenger'
      },
      token: token
    });

  } catch (error) {
    console.error('❌ Signup error:', error.message);

    if (error.code === 'auth/email-already-exists') {
      return res.status(400).json({ 
        success: false, 
        error: 'Email already registered' 
      });
    }
    if (error.code === 'auth/invalid-email') {
      return res.status(400).json({ 
        success: false, 
        error: 'Invalid email format' 
      });
    }
    if (error.code === 'auth/weak-password') {
      return res.status(400).json({ 
        success: false, 
        error: 'Password too weak. Use at least 6 characters' 
      });
    }

    res.status(400).json({ 
      success: false, 
      error: error.message || 'Signup failed' 
    });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({ 
        success: false, 
        error: 'Email and password required' 
      });
    }

    if (!process.env.JWT_SECRET) {
      console.error('❌ JWT_SECRET not configured in .env file');
      return res.status(500).json({ 
        success: false, 
        error: 'Server configuration error' 
      });
    }

    if (!process.env.FIREBASE_WEB_API_KEY) {
      console.error('❌ FIREBASE_WEB_API_KEY not configured in .env file');
      return res.status(500).json({ 
        success: false, 
        error: 'Server configuration error: Firebase Web API Key not set' 
      });
    }

    try {
      // Get user by email from Firebase Auth
      const userRecord = await auth.getUserByEmail(email);

      // Verify password using Firebase REST API
      const firebaseRestApiUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${process.env.FIREBASE_WEB_API_KEY}`;
      
      const passwordVerificationResponse = await fetch(firebaseRestApiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: email,
          password: password,
          returnSecureToken: true
        })
      });

      const passwordVerificationData = await passwordVerificationResponse.json();

      if (!passwordVerificationResponse.ok || passwordVerificationData.error) {
        console.warn(`❌ Invalid password for user: ${email}`);
        return res.status(401).json({ 
          success: false, 
          error: 'Invalid email or password' 
        });
      }

      // Fetch user data from Firestore
      const userDoc = await db.collection('users').doc(userRecord.uid).get();

      if (!userDoc.exists) {
        return res.status(401).json({ 
          success: false, 
          error: 'User data not found' 
        });
      }

      const userData = userDoc.data();

      // Generate JWT token
      const token = jwt.sign(
        { uid: userRecord.uid, email: email },
        process.env.JWT_SECRET,
        { expiresIn: '24h' }
      );

      console.log(`✅ Login successful: ${email}`);

      res.status(200).json({
        success: true,
        user: {
          uid: userData.uid,
          email: userData.email,
          fullName: userData.fullName,
          role: userData.role
        },
        token: token
      });

    } catch (firebaseError) {
      if (firebaseError.code === 'auth/user-not-found') {
        return res.status(401).json({ 
          success: false, 
          error: 'No account found with this email' 
        });
      }
      console.error('Firebase error:', firebaseError.message);
      throw firebaseError;
    }

  } catch (error) {
    console.error('❌ Login error:', error.message);
    res.status(401).json({ 
      success: false, 
      error: error.message || 'Login failed' 
    });
  }
});

// ============================================
// 2. DUTY INITIALIZATION (Step 1)
// ============================================

app.post('/api/trips/initialize', verifyToken, async (req, res) => {
  try {
    const { driverId, vehicleId, routeId } = req.body;

    const driver = await db.collection('users').doc(driverId).get();
    if (!driver.exists || driver.data().role !== 'driver') {
      return res.status(401).json({ success: false, error: 'Not authorized as driver' });
    }

    const tripRef = await db.collection('liveTrips').add({
      driverId,
      vehicleId,
      routeId,
      status: 'active',
      startTime: admin.firestore.FieldValue.serverTimestamp(),
      endTime: null,
      currentLocation: null,
      currentSpeed: 0,
      occupancy: 0,
      crowdLevel: 'low',
      emergencyAlertActive: false
    });

    const tripId = tripRef.id;
    console.log(`✅ Trip initialized: ${tripId}`);

    res.json({
      success: true,
      tripId,
      message: 'Trip duty started successfully'
    });
  } catch (error) {
    console.error('Trip initialization error:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

// ============================================
// 3. LIVE DATA PROPAGATION (Step 2)
// ============================================

app.post('/api/trips/:tripId/gps', verifyToken, async (req, res) => {
  try {
    const { tripId } = req.params;
    const { latitude, longitude, speed } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({ success: false, error: 'GPS coordinates required' });
    }

    await db.collection('liveTrips').doc(tripId).update({
      currentLocation: new admin.firestore.GeoPoint(latitude, longitude),
      currentSpeed: speed || 0,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });

    io.emit('gps-update', {
      tripId,
      location: { latitude, longitude },
      speed,
      timestamp: new Date()
    });

    await recalculateETAs(tripId, latitude, longitude);

    res.json({ success: true, message: 'GPS data received and broadcasted' });
  } catch (error) {
    console.error('GPS update error:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

app.get('/api/trips/:tripId', async (req, res) => {
  try {
    const { tripId } = req.params;
    const trip = await db.collection('liveTrips').doc(tripId).get();

    if (!trip.exists) {
      return res.status(404).json({ success: false, error: 'Trip not found' });
    }

    const tripData = trip.data();
    const route = await db.collection('routes').doc(tripData.routeId).get();

    res.json({
      success: true,
      trip: {
        id: tripId,
        ...tripData,
        currentLocation: {
          latitude: tripData.currentLocation?.latitude,
          longitude: tripData.currentLocation?.longitude
        },
        route: route.data()
      }
    });
  } catch (error) {
    console.error('Fetch trip error:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

// ============================================
// 4. CROWD INTELLIGENCE (Step 3)
// ============================================

app.post('/api/reports/crowd', verifyToken, async (req, res) => {
  try {
    const { tripId, crowdLevel, location } = req.body;
    const userId = req.user.uid;

    const trip = await db.collection('liveTrips').doc(tripId).get();
    if (!trip.exists) {
      return res.status(404).json({ success: false, error: 'Trip not found' });
    }

    const busLocation = trip.data().currentLocation;
    const distance = calculateDistance(
      location.latitude, location.longitude,
      busLocation.latitude, busLocation.longitude
    );

    if (distance > 0.5) {
      return res.status(400).json({ success: false, error: 'User not near the bus' });
    }

    await db.collection('crowdReports').add({
      tripId,
      userId,
      crowdLevel,
      location,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    const aggregatedSentiment = await aggregateCrowdSentiment(tripId);

    await db.collection('liveTrips').doc(tripId).update({
      crowdLevel: aggregatedSentiment
    });

    io.emit('crowd-update', {
      tripId,
      crowdLevel: aggregatedSentiment,
      timestamp: new Date()
    });

    res.json({
      success: true,
      message: 'Crowd report received',
      aggregatedSentiment
    });
  } catch (error) {
    console.error('Crowd report error:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

// ============================================
// 5. SMART ROUTING & ALERTS (Step 4)
// ============================================

app.post('/api/route/search', async (req, res) => {
  try {
    const { startPoint, endPoint } = req.body;

    const routes = await db.collection('routes').get();
    const matchingRoutes = [];

    routes.forEach(doc => {
      matchingRoutes.push({
        routeId: doc.id,
        ...doc.data(),
        estimatedTime: '25 mins'
      });
    });

    res.json({
      success: true,
      routes: matchingRoutes
    });
  } catch (error) {
    console.error('Route search error:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

app.post('/api/alerts/emergency', verifyToken, async (req, res) => {
  try {
    const { tripId, alertType, description } = req.body;
    const driverId = req.user.uid;

    await db.collection('emergencyAlerts').add({
      tripId,
      driverId,
      alertType,
      description,
      status: 'active',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    await db.collection('liveTrips').doc(tripId).update({
      emergencyAlertActive: true
    });

    const trip = await db.collection('liveTrips').doc(tripId).get();
    const routeId = trip.data().routeId;

    io.emit('emergency-alert', {
      tripId,
      routeId,
      alertType,
      description,
      timestamp: new Date()
    });

    res.json({ success: true, message: 'Emergency alert sent' });
  } catch (error) {
    console.error('Emergency alert error:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

// ============================================
// 6. TRIP CONCLUSION & ANALYTICS (Step 5)
// ============================================

app.post('/api/trips/:tripId/end', verifyToken, async (req, res) => {
  try {
    const { tripId } = req.params;

    await db.collection('liveTrips').doc(tripId).update({
      status: 'completed',
      endTime: admin.firestore.FieldValue.serverTimestamp()
    });

    const trip = await db.collection('liveTrips').doc(tripId).get();
    const tripData = trip.data();

    await db.collection('analytics').add({
      tripId,
      driverId: tripData.driverId,
      routeId: tripData.routeId,
      vehicleId: tripData.vehicleId,
      occupancy: tripData.occupancy,
      crowdLevel: tripData.crowdLevel,
      completedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    await updateImpactPoints(tripId);

    res.json({
      success: true,
      message: 'Trip completed and archived'
    });
  } catch (error) {
    console.error('Trip end error:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

// ============================================
// 7. ADMIN DASHBOARD
// ============================================

app.get('/api/admin/analytics/:routeId', verifyToken, async (req, res) => {
  try {
    const { routeId } = req.params;

    const user = await db.collection('users').doc(req.user.uid).get();
    if (user.data().role !== 'admin') {
      return res.status(403).json({ success: false, error: 'Not authorized' });
    }

    const analytics = await db.collection('analytics')
      .where('routeId', '==', routeId)
      .orderBy('completedAt', 'desc')
      .limit(30)
      .get();

    const data = analytics.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    res.json({
      success: true,
      analytics: data,
      statistics: {
        totalTrips: data.length,
        averageOccupancy: data.length > 0 ? data.reduce((sum, trip) => sum + (trip.occupancy || 0), 0) / data.length : 0
      }
    });
  } catch (error) {
    console.error('Analytics error:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

// ============================================
// 8. HEALTH CHECK
// ============================================

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    message: 'TransitLive Pro Backend is running',
    firebase: 'connected',
    database: 'operational'
  });
});

app.get('/api/status', (req, res) => {
  res.json({
    status: 'operational',
    database: 'connected',
    timestamp: new Date(),
    version: '1.0.0'
  });
});

// ============================================
// UTILITIES
// ============================================

function verifyToken(req, res, next) {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) {
    return res.status(401).json({ success: false, error: 'No token provided' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ success: false, error: 'Invalid token' });
  }
}

function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

async function aggregateCrowdSentiment(tripId) {
  const reports = await db.collection('crowdReports')
    .where('tripId', '==', tripId)
    .orderBy('timestamp', 'desc')
    .limit(10)
    .get();

  if (reports.empty) return 'low';

  let highCount = 0, mediumCount = 0;
  reports.forEach(doc => {
    const level = doc.data().crowdLevel;
    if (level === 'high') highCount++;
    else if (level === 'medium') mediumCount++;
  });

  const total = reports.size;
  if ((highCount / total) * 100 > 40) return 'high';
  if ((mediumCount / total) * 100 > 40) return 'medium';
  return 'low';
}

async function recalculateETAs(tripId, latitude, longitude) {
  const trip = await db.collection('liveTrips').doc(tripId).get();
  const route = await db.collection('routes').doc(trip.data().routeId).get();
  
  const stops = route.data().stops || [];
  const etaData = stops.map(stop => {
    const distance = calculateDistance(latitude, longitude, stop.latitude, stop.longitude);
    const eta = Math.round(distance * 2.5);
    return { stop: stop.name, eta };
  });

  await db.collection('liveTrips').doc(tripId).update({ etaData });
  io.emit('eta-update', { tripId, etaData });
}

async function updateImpactPoints(tripId) {
  const reports = await db.collection('crowdReports')
    .where('tripId', '==', tripId)
    .get();

  reports.forEach(async (reportDoc) => {
    const userId = reportDoc.data().userId;
    await db.collection('users').doc(userId).update({
      impactPoints: admin.firestore.FieldValue.increment(10)
    });
  });
}

// ============================================
// WEBSOCKET
// ============================================

io.on('connection', (socket) => {
  console.log(`✅ Client connected: ${socket.id}`);

  socket.on('subscribe-trip', (tripId) => {
    socket.join(`trip-${tripId}`);
  });

  socket.on('unsubscribe-trip', (tripId) => {
    socket.leave(`trip-${tripId}`);
  });

  socket.on('disconnect', () => {
    console.log(`❌ Client disconnected: ${socket.id}`);
  });
});

// ============================================
// START SERVER
// ============================================

server.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════╗
║   TransitLive Pro Backend Running      ║
║   🚀 Server: http://localhost:${PORT}     ║
║   📊 Firebase: Connected               ║
╚════════════════════════════════════════╝
  `);
});

module.exports = { app, io };
