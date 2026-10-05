// ========================================
// TRANSIT LIVE PRO - COMPLETE BACKEND
// Real-time Public Transport Tracking System
// ========================================

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const os = require('os');
const socketIO = require('socket.io');
const admin = require('firebase-admin');
const jwt = require('jsonwebtoken');
const axios = require('axios');
const { findMatchingBuses, normalizeRoute, mapCurrentLocation } = require('./route-matcher');

// ============================================
// FIREBASE INITIALIZATION
// ============================================

const serviceAccount = require('./firebase-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

function getLocalIpAddress() {
  const interfaces = os.networkInterfaces();

  for (const interfaceName of Object.keys(interfaces)) {
    for (const details of interfaces[interfaceName] || []) {
      if (details.family === 'IPv4' && !details.internal) {
        return details.address;
      }
    }
  }

  return 'localhost';
}

// ============================================
// EXPRESS & SOCKET.IO SETUP
// ============================================

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const FIREBASE_WEB_API_KEY = process.env.FIREBASE_WEB_API_KEY;

// ============================================
// MIDDLEWARE
// ============================================

app.use(cors());
app.use(express.json());

// Token Verification Middleware
const verifyToken = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(401).json({ success: false, error: 'No token provided' });
  }
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ success: false, error: 'Invalid token' });
  }
};

// ============================================
// HELPER FUNCTIONS
// ============================================

// Distance calculation (Haversine formula)
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Calculate ETA
async function calculateETA(tripId, currentLat, currentLon) {
  try {
    const trip = await db.collection('liveTrips').doc(tripId).get();
    if (!trip.exists) return null;

    const tripData = trip.data();
    const route = await db.collection('routes').doc(tripData.routeId).get();
    if (!route.exists) return null;

    const routeData = route.data();
    const stops = tripData.direction === 'inbound'
      ? [...(routeData.stops || [])].reverse()
      : routeData.stops || [];

    if (stops.length === 0) return null;

    const normalizedStops = stops.map((stop) => ({
      ...stop,
      latitude: Number(stop.latitude ?? stop.lat),
      longitude: Number(stop.longitude ?? stop.lng),
    })).filter((stop) => Number.isFinite(stop.latitude) && Number.isFinite(stop.longitude));
    let nearestIndex = -1;
    let nearestDistance = Infinity;
    normalizedStops.forEach((stop, index) => {
      const distance = calculateDistance(currentLat, currentLon, stop.latitude, stop.longitude);
      if (distance < nearestDistance) { nearestDistance = distance; nearestIndex = index; }
    });
    const nextIndex = nearestDistance < 0.1 ? nearestIndex + 1 : nearestIndex;
    const nextStop = normalizedStops[nextIndex];
    const distanceToNextStop = nextStop
      ? calculateDistance(currentLat, currentLon, nextStop.latitude, nextStop.longitude)
      : 0;

    if (!nextStop) return null;

    // Estimate speed (default 40 km/h for city buses)
    const estimatedSpeed = Math.min(80, Math.max(12, tripData.currentSpeedKmh || 25));
    const timeInHours = distanceToNextStop / estimatedSpeed;
    const timeInMinutes = Math.round(timeInHours * 60);

    return {
      nextStopName: nextStop.name,
      nextStopId: nextStop.id,
      distanceKm: Math.round(distanceToNextStop * 10) / 10,
      etaMinutes: timeInMinutes,
      estimatedArrivalTime: new Date(Date.now() + timeInMinutes * 60000)
    };
  } catch (error) {
    console.error('ETA calculation error:', error);
    return null;
  }
}

function serializeTrip(id, data, route = null) {
  const normalizedRoute = route ? normalizeRoute(route) : null;
  const directedRoute = normalizedRoute && data.direction === 'inbound'
    ? { ...normalizedRoute, from: normalizedRoute.to, to: normalizedRoute.from, stops: [...(normalizedRoute.stops || [])].reverse() }
    : normalizedRoute;
  return {
    id,
    ...data,
    currentLocation: mapCurrentLocation(data.currentLocation),
    startTime: data.startTime?.toDate?.().toISOString?.() || data.startTime || null,
    lastUpdated: data.lastUpdated?.toDate?.().toISOString?.() || data.lastUpdated || null,
    route: directedRoute ? { id: data.routeId, ...directedRoute } : undefined,
  };
}

function firestoreDate(value) {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate();
  const parsed = value instanceof Date ? value : new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function isTripLive(data, maxAgeMs = 15 * 60 * 1000) {
  const lastUpdated = firestoreDate(data.lastUpdated);
  const startTime = firestoreDate(data.startTime);
  const latestActivity = lastUpdated || startTime;
  return data.status === 'active' &&
    typeof data.driverId === 'string' && data.driverId.length > 0 &&
    typeof data.vehicleId === 'string' && data.vehicleId.trim().length > 0 &&
    latestActivity !== null &&
    Date.now() - latestActivity.getTime() <= maxAgeMs;
}

// Aggregate crowd sentiment
async function aggregateCrowdSentiment(tripId) {
  try {
    const reports = await db.collection('crowdReports')
      .where('tripId', '==', tripId)
      .orderBy('timestamp', 'desc')
      .limit(20)
      .get();

    if (reports.empty) return 'low';

    let levels = { available: 0, standing: 0, full: 0, conductor: 0 };
    let lastConductorReport = null;

    reports.forEach(doc => {
      const data = doc.data();

      if (data.crowdLevel === 'available') levels.available++;
      if (data.crowdLevel === 'standing') levels.standing++;
      if (data.crowdLevel === 'full') levels.full++;

      // Check if conductor (conductor reports have higher weight)
      if (data.userRole === 'conductor' && !lastConductorReport) {
        lastConductorReport = data.crowdLevel;
      }
    });

    // Conductor report takes priority
    if (lastConductorReport) {
      return lastConductorReport;
    }

    // Passenger voting logic
    const total = levels.available + levels.standing + levels.full;
    if (total === 0) return 'low';

    if (levels.full > total * 0.6) return 'full';
    if (levels.standing > total * 0.5) return 'standing';
    return 'available';
  } catch (error) {
    console.error('Crowd aggregation error:', error);
    return 'low';
  }
}

// ============================================
// 1. AUTHENTICATION ENDPOINTS
// ============================================

app.post('/api/auth/signup', async (req, res) => {
  try {
    const { email, password, fullName, role, phone, vehicle } = req.body;

    if (!email || !password || !fullName) {
      return res.status(400).json({ 
        success: false, 
        error: 'Missing required fields' 
      });
    }

    if (password.length < 6) {
      return res.status(400).json({ 
        success: false, 
        error: 'Password must be at least 6 characters' 
      });
    }

    // Check if user exists
    const existingUser = await db.collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (!existingUser.empty) {
      return res.status(400).json({ 
        success: false, 
        error: 'Email already registered' 
      });
    }

    // Create Firebase user
    const userRecord = await auth.createUser({
      email: email,
      password: password,
      displayName: fullName
    });

    // Store user in Firestore
    const userData = {
      uid: userRecord.uid,
      email: email,
      fullName: fullName,
      role: role || 'passenger',
      phone: phone || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      impactPoints: 0,
      status: 'active'
    };

    if (role === 'driver' && vehicle) {
      userData.vehicle = vehicle;
      userData.licenseNumber = vehicle.licenseNumber || null;
    }

    await db.collection('users').doc(userRecord.uid).set(userData);

    // Generate JWT token
    const token = jwt.sign(
      { uid: userRecord.uid, email: email, role: role || 'passenger' },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    console.log(`✅ Signup successful: ${email} (${role})`);

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
    console.error('Signup error:', error.message);
    res.status(400).json({ 
      success: false, 
      error: error.message || 'Signup failed' 
    });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ 
        success: false, 
        error: 'Email and password required' 
      });
    }

    if (!FIREBASE_WEB_API_KEY) {
      return res.status(500).json({ 
        success: false, 
        error: 'Server configuration error' 
      });
    }

    // Get user by email
    const userRecord = await auth.getUserByEmail(email);

    // Verify password using Firebase REST API
    const firebaseRestApiUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_WEB_API_KEY}`;
    
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
      { uid: userRecord.uid, email: email, role: userData.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    console.log(`✅ Login successful: ${email}`);

    res.status(200).json({
      success: true,
      user: {
        uid: userData.uid,
        email: userData.email,
        fullName: userData.fullName,
        role: userData.role,
        impactPoints: userData.impactPoints || 0
      },
      token: token
    });

  } catch (error) {
    console.error('Login error:', error.message);
    res.status(401).json({ 
      success: false, 
      error: error.message || 'Login failed' 
    });
  }
});

app.post('/api/auth/logout', verifyToken, async (req, res) => {
  try {
    // Optional: Revoke tokens or clear sessions
    res.json({ success: true, message: 'Logged out successfully' });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

// ============================================
// 2. ROUTES ENDPOINTS
// ============================================

app.get('/api/routes', async (req, res) => {
  try {
    const routes = await db.collection('routes').get();
    const routesList = routes.docs.map(doc => ({
      id: doc.id,
      ...normalizeRoute(doc.data())
    }));

    res.json({ success: true, routes: routesList });
  } catch (error) {
    console.error('Fetch routes error:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

app.get('/api/routes/:routeId', async (req, res) => {
  try {
    const { routeId } = req.params;
    const route = await db.collection('routes').doc(routeId).get();

    if (!route.exists) {
      return res.status(404).json({ success: false, error: 'Route not found' });
    }

    res.json({ 
      success: true, 
      route: {
        id: routeId,
        ...normalizeRoute(route.data())
      }
    });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

app.get('/api/routes/:routeId/active-trips', async (req, res) => {
  try {
    const { routeId } = req.params;
    const trips = await db.collection('liveTrips')
      .where('routeId', '==', routeId)
      .where('status', '==', 'active')
      .get();

    const tripsList = trips.docs
      .filter((doc) => isTripLive(doc.data()))
      .map((doc) => serializeTrip(doc.id, doc.data()));

    res.json({ success: true, trips: tripsList });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

app.get('/api/trips/active', async (req, res) => {
  try {
    const snapshot = await db.collection('liveTrips').where('status', '==', 'active').get();
    const liveDocs = snapshot.docs.filter((doc) => isTripLive(doc.data()));
    const routeIds = [...new Set(liveDocs.map((doc) => doc.data().routeId).filter(Boolean))];
    const routeDocs = await Promise.all(routeIds.map((id) => db.collection('routes').doc(id).get()));
    const routes = new Map(routeDocs.filter((doc) => doc.exists).map((doc) => [doc.id, doc.data()]));
    const trips = liveDocs.map((doc) => serializeTrip(doc.id, doc.data(), routes.get(doc.data().routeId)));
    res.json({ success: true, trips, count: trips.length });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

app.post('/api/routes/find-buses', async (req, res) => {
  try {
    const {
      passengerLat,
      passengerLng,
      destinationLat,
      destinationLng,
    } = req.body;

    const coordinates = [passengerLat, passengerLng, destinationLat, destinationLng];
    const allNumbers = coordinates.every((value) => Number.isFinite(Number(value)));

    if (!allNumbers) {
      return res.status(400).json({
        success: false,
        error: 'passengerLat, passengerLng, destinationLat, destinationLng must be valid numbers',
      });
    }

    const activeTripsSnapshot = await db.collection('liveTrips')
      .where('status', '==', 'active')
      .get();

    const activeTrips = activeTripsSnapshot.docs
      .filter((doc) => isTripLive(doc.data()))
      .map((doc) => ({
      id: doc.id,
      ...doc.data(),
      }));

    if (activeTrips.length === 0) {
      return res.json({ success: true, matches: [], count: 0 });
    }

    const routeIds = [...new Set(activeTrips
      .map((trip) => trip.routeId)
      .filter((routeId) => typeof routeId === 'string' && routeId.trim().length > 0))];

    const routeDocs = await Promise.all(
      routeIds.map((routeId) => db.collection('routes').doc(routeId).get())
    );

    const routesById = new Map();
    routeDocs.forEach((doc) => {
      if (doc.exists) {
        routesById.set(doc.id, doc.data());
      }
    });

    const matches = findMatchingBuses({
      passengerLat: Number(passengerLat),
      passengerLng: Number(passengerLng),
      destinationLat: Number(destinationLat),
      destinationLng: Number(destinationLng),
      activeTrips,
      routesById,
      maxStopDistanceKm: 0.5,
    });

    return res.json({
      success: true,
      matches,
      count: matches.length,
    });
  } catch (error) {
    console.error('Find buses error:', error);
    return res.status(400).json({ success: false, error: error.message });
  }
});

// ============================================
// 3. TRIP MANAGEMENT ENDPOINTS
// ============================================

app.post('/api/trips/initialize', verifyToken, async (req, res) => {
  try {
    const { vehicleId, routeId, conductorId, capacity, direction } = req.body;
    const driverId = req.user.uid;

    if (typeof vehicleId !== 'string' || vehicleId.trim().length < 2 || typeof routeId !== 'string') {
      return res.status(400).json({ success: false, error: 'A route and valid vehicle ID are required' });
    }

    // Verify driver role
    const driver = await db.collection('users').doc(driverId).get();
    if (!driver.exists || driver.data().role !== 'driver') {
      return res.status(401).json({ 
        success: false, 
        error: 'Only drivers can initialize trips' 
      });
    }

    // Check if route exists
    const route = await db.collection('routes').doc(routeId).get();
    if (!route.exists) {
      return res.status(404).json({ 
        success: false, 
        error: 'Route not found' 
      });
    }

    const existingTrip = await db.collection('liveTrips')
      .where('driverId', '==', driverId)
      .get();
    const activeTrip = existingTrip.docs.find((doc) => doc.data().status === 'active');
    if (activeTrip) {
      return res.status(409).json({
        success: false,
        error: 'You already have an active trip. End it before starting another.',
        tripId: activeTrip.id,
      });
    }

    // Create active trip
    const tripRef = await db.collection('liveTrips').add({
      driverId,
      vehicleId: vehicleId.trim(),
      routeId,
      direction: direction === 'inbound' ? 'inbound' : 'outbound',
      conductorId: conductorId || null,
      status: 'active',
      startTime: admin.firestore.FieldValue.serverTimestamp(),
      endTime: null,
      currentLocation: null,
      currentSpeedKmh: 0,
      occupancy: 0,
      capacity: Math.min(100, Math.max(1, Number(capacity) || 55)),
      crowdLevel: 'available',
      emergencyAlertActive: false,
      eta: null,
      passengers: [],
      completedStops: [],
      totalDistance: 0,
      estimatedDuration: route.data().estimatedDurationMinutes || 60
    });

    const tripId = tripRef.id;

    // Broadcast trip started
    io.emit('trip-started', {
      tripId,
      routeId,
      driverId,
      vehicleId,
      occupancy: 0,
      capacity: Math.min(100, Math.max(1, Number(capacity) || 55)),
      route: { id: routeId, ...normalizeRoute(route.data()) },
      timestamp: new Date()
    });

    console.log(`✅ Trip initialized: ${tripId} on route ${routeId}`);

    res.status(200).json({
      success: true,
      tripId,
      message: 'Trip duty started successfully',
      route: route.data()
    });

  } catch (error) {
    console.error('Trip initialization error:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

app.post('/api/trips/:tripId/gps', verifyToken, async (req, res) => {
  try {
    const { tripId } = req.params;
    const { latitude, longitude, speedMps, speed, accuracy } = req.body;
    const lat = Number(latitude);
    const lng = Number(longitude);

    if (!Number.isFinite(lat) || !Number.isFinite(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return res.status(400).json({ 
        success: false, 
        error: 'GPS coordinates required' 
      });
    }

    const tripRef = db.collection('liveTrips').doc(tripId);
    const tripSnapshot = await tripRef.get();
    if (!tripSnapshot.exists || tripSnapshot.data().status !== 'active') {
      return res.status(404).json({ success: false, error: 'Active trip not found' });
    }
    const tripData = tripSnapshot.data();
    if (tripData.driverId !== req.user.uid && tripData.conductorId !== req.user.uid) {
      return res.status(403).json({ success: false, error: 'Not authorized to update this trip' });
    }
    const measuredSpeedMps = Math.max(0, Number(speedMps ?? speed) || 0);
    const currentSpeedKmh = Math.min(120, measuredSpeedMps * 3.6);

    // Update trip with GPS data
    await tripRef.update({
      currentLocation: new admin.firestore.GeoPoint(lat, lng),
      currentSpeedKmh,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });

    // Calculate ETA
    const eta = await calculateETA(tripId, lat, lng);

    // Store GPS history (optional - for analytics)
    await db.collection('gpsHistory').add({
      tripId,
      location: new admin.firestore.GeoPoint(lat, lng),
      speedKmh: currentSpeedKmh,
      accuracy: accuracy || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    // Emit real-time GPS update to all connected clients
    io.emit('gps-update', {
      tripId,
      location: { latitude: lat, longitude: lng },
      speedKmh: currentSpeedKmh,
      eta: eta,
      timestamp: new Date()
    });

    res.json({ 
      success: true, 
      message: 'GPS data received',
      eta: eta 
    });

  } catch (error) {
    console.error('GPS update error:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

app.patch('/api/trips/:tripId/occupancy', verifyToken, async (req, res) => {
  try {
    const { tripId } = req.params;
    const tripRef = db.collection('liveTrips').doc(tripId);
    const snapshot = await tripRef.get();
    if (!snapshot.exists || snapshot.data().status !== 'active') {
      return res.status(404).json({ success: false, error: 'Active trip not found' });
    }
    const trip = snapshot.data();
    if (trip.driverId !== req.user.uid && trip.conductorId !== req.user.uid) {
      return res.status(403).json({ success: false, error: 'Not authorized to update this trip' });
    }
    const capacity = Math.min(100, Math.max(1, Number(trip.capacity) || 55));
    const occupancy = Math.min(capacity, Math.max(0, Math.round(Number(req.body.occupancy) || 0)));
    const ratio = occupancy / capacity;
    const crowdLevel = ratio >= 0.9 ? 'full' : ratio >= 0.6 ? 'standing' : 'available';
    await tripRef.update({ occupancy, capacity, crowdLevel, lastUpdated: admin.firestore.FieldValue.serverTimestamp() });
    const update = { tripId, occupancy, capacity, crowdLevel, timestamp: new Date() };
    io.emit('crowd-update', update);
    res.json({ success: true, ...update });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

app.get('/api/trips/my-active', verifyToken, async (req, res) => {
  try {
    const snapshot = await db.collection('liveTrips')
      .where('driverId', '==', req.user.uid)
      .get();
    const activeDoc = snapshot.docs.find((doc) => doc.data().status === 'active');
    if (!activeDoc) return res.json({ success: true, trip: null });
    const data = activeDoc.data();
    const routeDoc = await db.collection('routes').doc(data.routeId).get();
    return res.json({
      success: true,
      trip: serializeTrip(activeDoc.id, data, routeDoc.exists ? routeDoc.data() : null),
    });
  } catch (error) {
    return res.status(400).json({ success: false, error: error.message });
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
    const driver = await db.collection('users').doc(tripData.driverId).get();

    res.json({
      success: true,
      trip: {
        id: tripId,
        ...tripData,
        currentLocation: tripData.currentLocation ? {
          latitude: tripData.currentLocation.latitude,
          longitude: tripData.currentLocation.longitude
        } : null,
        route: normalizeRoute(route.data()),
        driver: driver.data()
      }
    });

  } catch (error) {
    console.error('Fetch trip error:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

app.post('/api/trips/:tripId/end', verifyToken, async (req, res) => {
  try {
    const { tripId } = req.params;
    const userId = req.user.uid;

    const trip = await db.collection('liveTrips').doc(tripId).get();
    if (!trip.exists) {
      return res.status(404).json({ success: false, error: 'Trip not found' });
    }

    const tripData = trip.data();

    // Verify authorization (driver or conductor)
    if (tripData.driverId !== userId && tripData.conductorId !== userId) {
      return res.status(401).json({ 
        success: false, 
        error: 'Not authorized to end this trip' 
      });
    }

    // End trip
    await db.collection('liveTrips').doc(tripId).update({
      status: 'completed',
      endTime: admin.firestore.FieldValue.serverTimestamp()
    });

    // Archive trip for analytics
    await db.collection('completedTrips').add({
      ...tripData,
      tripId: tripId,
      completedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Award impact points to driver
    await db.collection('users').doc(tripData.driverId).update({
      impactPoints: admin.firestore.FieldValue.increment(50)
    });

    // Emit trip ended event
    io.emit('trip-ended', {
      tripId,
      endTime: new Date()
    });

    console.log(`✅ Trip completed: ${tripId}`);

    res.json({ 
      success: true, 
      message: 'Trip ended successfully',
      impactPointsAwarded: 50 
    });

  } catch (error) {
    console.error('Trip end error:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

// ============================================
// 4. FREE DIGITAL TICKETS
// ============================================

app.get('/api/tickets/mine', verifyToken, async (req, res) => {
  try {
    const snapshot = await db.collection('tickets').where('passengerId', '==', req.user.uid).get();
    const tickets = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.().toISOString?.() || null,
    })).sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)));
    res.json({ success: true, tickets });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

app.post('/api/tickets', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'passenger') {
      return res.status(403).json({ success: false, error: 'Only passengers can get tickets' });
    }
    const { tripId, pickupStopIndex, dropoffStopIndex, passengerCount } = req.body;
    const count = Math.min(4, Math.max(1, Math.round(Number(passengerCount) || 1)));
    const tripDoc = await db.collection('liveTrips').doc(String(tripId || '')).get();
    if (!tripDoc.exists || !isTripLive(tripDoc.data())) {
      return res.status(404).json({ success: false, error: 'This vehicle is no longer active' });
    }
    const trip = tripDoc.data();
    const routeDoc = await db.collection('routes').doc(trip.routeId).get();
    if (!routeDoc.exists) return res.status(404).json({ success: false, error: 'Route not found' });
    const route = normalizeRoute(routeDoc.data());
    const stops = trip.direction === 'inbound' ? [...(route.stops || [])].reverse() : route.stops || [];
    const pickup = Number(pickupStopIndex);
    const dropoff = Number(dropoffStopIndex);
    if (!Number.isInteger(pickup) || !Number.isInteger(dropoff) || pickup < 0 || dropoff <= pickup || dropoff >= stops.length) {
      return res.status(400).json({ success: false, error: 'Choose a pickup stop before the drop-off stop' });
    }
    const capacity = Number(trip.capacity) || 55;
    if ((Number(trip.reservedSeats) || 0) + count > capacity) {
      return res.status(409).json({ success: false, error: 'Not enough space on this vehicle' });
    }
    const ticketCode = `TL-${Date.now().toString(36).toUpperCase()}-${Math.random().toString(36).slice(2, 6).toUpperCase()}`;
    const ticketData = {
      ticketCode,
      passengerId: req.user.uid,
      tripId: tripDoc.id,
      routeId: trip.routeId,
      routeNumber: route.routeNumber || trip.routeId,
      vehicleId: trip.vehicleId,
      pickupStop: stops[pickup]?.name || `Stop ${pickup + 1}`,
      dropoffStop: stops[dropoff]?.name || `Stop ${dropoff + 1}`,
      pickupStopIndex: pickup,
      dropoffStopIndex: dropoff,
      passengerCount: count,
      fare: route.fare || 'Pay on bus',
      status: 'confirmed',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    const ticketRef = db.collection('tickets').doc();
    await db.runTransaction(async (transaction) => {
      const freshTripDoc = await transaction.get(tripDoc.ref);
      const freshTrip = freshTripDoc.data();
      if (!freshTrip || !isTripLive(freshTrip)) throw new Error('This vehicle is no longer active');
      const reservedSeats = Number(freshTrip.reservedSeats) || 0;
      if (reservedSeats + count > (Number(freshTrip.capacity) || 55)) {
        throw new Error('Not enough space on this vehicle');
      }
      transaction.update(tripDoc.ref, { reservedSeats: reservedSeats + count });
      transaction.set(ticketRef, ticketData);
    });
    res.status(201).json({
      success: true,
      ticket: { id: ticketRef.id, ...ticketData, createdAt: new Date().toISOString() },
    });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

// ============================================
// 5. TRIP CANCELLATION ENDPOINT (ADMIN ONLY)
// ============================================

app.post('/api/trips/:tripId/cancel', verifyToken, async (req, res) => {
  try {
    const tripId = req.params.tripId;
    const userId = req.user.uid;
    const { reason } = req.body;

    if (!reason) {
      return res.status(400).json({ 
        success: false, 
        error: 'Cancellation reason is required' 
      });
    }

    // Get user role to verify admin permission
    const userDoc = await db.collection('users').doc(userId).get();
    const userRole = userDoc.data()?.role;

    if (userRole !== 'admin') {
      return res.status(403).json({ 
        success: false, 
        error: 'Only admins can cancel trips' 
      });
    }

    const trip = await db.collection('liveTrips').doc(tripId).get();
    if (!trip.exists) {
      return res.status(404).json({ success: false, error: 'Trip not found' });
    }

    const tripData = trip.data();

    // Cancel trip
    await db.collection('liveTrips').doc(tripId).update({
      status: 'cancelled',
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      cancelledBy: userId,
      cancellationReason: reason
    });

    // Archive cancelled trip for analytics
    await db.collection('completedTrips').add({
      ...tripData,
      tripId: tripId,
      status: 'cancelled',
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      cancelledBy: userId,
      cancellationReason: reason
    });

    // Emit trip cancelled event to notify passengers
    io.emit('trip-cancelled', {
      tripId,
      reason,
      cancelledAt: new Date(),
      route: tripData.routeId,
      vehicleId: tripData.vehicleId
    });

    // Send push notifications to affected passengers
    // This would integrate with FCM (Firebase Cloud Messaging)
    io.emit('emergency-notification', {
      title: 'Trip Cancelled',
      message: `Trip ${tripData.routeId} has been cancelled due to ${reason}`,
      tripId,
      type: 'trip_cancellation'
    });

    console.log(`❌ Trip cancelled by admin: ${tripId}, reason: ${reason}`);

    res.json({ 
      success: true, 
      message: 'Trip cancelled successfully',
      reason: reason,
      cancelledAt: new Date()
    });

  } catch (error) {
    console.error('Trip cancellation error:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

// ============================================
// 5. CROWD INTELLIGENCE ENDPOINTS
// ============================================

app.post('/api/reports/crowd', verifyToken, async (req, res) => {
  try {
    const { tripId, crowdLevel, userLocation } = req.body;
    const userId = req.user.uid;

    if (!tripId || !crowdLevel) {
      return res.status(400).json({ 
        success: false, 
        error: 'tripId and crowdLevel required' 
      });
    }

    // Get trip
    const trip = await db.collection('liveTrips').doc(tripId).get();
    if (!trip.exists) {
      return res.status(404).json({ success: false, error: 'Trip not found' });
    }

    const tripData = trip.data();

    // Validate user is near the bus (500m radius)
    if (tripData.currentLocation && userLocation) {
      const distance = calculateDistance(
        userLocation.latitude, 
        userLocation.longitude,
        tripData.currentLocation.latitude, 
        tripData.currentLocation.longitude
      );

      if (distance > 0.5) {
        return res.status(400).json({ 
          success: false, 
          error: 'You are too far from the bus to report' 
        });
      }
    }

    // Get user to check if conductor
    const user = await db.collection('users').doc(userId).get();
    const userData = user.data();

    // Store crowd report
    await db.collection('crowdReports').add({
      tripId,
      userId,
      userRole: userData.role,
      crowdLevel,
      location: userLocation,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    // Recalculate crowd sentiment
    const aggregatedSentiment = await aggregateCrowdSentiment(tripId);

    // Update trip with new crowd level
    await db.collection('liveTrips').doc(tripId).update({
      crowdLevel: aggregatedSentiment
    });

    // Award impact points for reporting
    await db.collection('users').doc(userId).update({
      impactPoints: admin.firestore.FieldValue.increment(5)
    });

    // Broadcast crowd update to all passengers
    io.emit('crowd-update', {
      tripId,
      crowdLevel: aggregatedSentiment,
      occupancy: tripData.occupancy || 0,
      capacity: tripData.capacity || 55,
      reportedBy: userData.role,
      timestamp: new Date()
    });

    console.log(`✅ Crowd report received: ${tripId} - ${aggregatedSentiment}`);

    res.json({ 
      success: true, 
      message: 'Crowd report submitted',
      crowdLevel: aggregatedSentiment,
      impactPointsAwarded: 5 
    });

  } catch (error) {
    console.error('Crowd report error:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

app.get('/api/trips/:tripId/crowd-reports', async (req, res) => {
  try {
    const { tripId } = req.params;
    const reports = await db.collection('crowdReports')
      .where('tripId', '==', tripId)
      .orderBy('timestamp', 'desc')
      .limit(50)
      .get();

    const reportsList = reports.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.json({ 
      success: true, 
      reports: reportsList 
    });

  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

// ============================================
// 5. EMERGENCY ALERTS ENDPOINTS
// ============================================

app.post('/api/alerts/emergency', verifyToken, async (req, res) => {
  try {
    const { tripId, alertType, message, location } = req.body;
    const userId = req.user.uid;

    const trip = await db.collection('liveTrips').doc(tripId).get();
    if (!trip.exists) {
      return res.status(404).json({ success: false, error: 'Trip not found' });
    }

    const tripData = trip.data();
    if (tripData.status !== 'active') {
      return res.status(400).json({ success: false, error: 'Trip is not active' });
    }
    if (tripData.driverId !== userId && tripData.conductorId !== userId) {
      return res.status(403).json({ success: false, error: 'Only assigned trip staff can broadcast alerts' });
    }

    // Get route info
    const route = await db.collection('routes').doc(tripData.routeId).get();

    // Create alert
    const alertRef = await db.collection('emergencyAlerts').add({
      tripId,
      userId,
      alertType,
      message,
      routeId: tripData.routeId,
      routeNumber: route.data()?.routeNumber || tripData.routeId,
      routeName: route.data()?.name || `${route.data()?.startPoint || ''} - ${route.data()?.endPoint || ''}`,
      vehicleId: tripData.vehicleId,
      location: location || tripData.currentLocation,
      status: 'active',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      resolvedAt: null
    });

    // Update trip
    await db.collection('liveTrips').doc(tripId).update({
      emergencyAlertActive: true
    });

    // Get all passengers on this trip
    const passengers = tripData.passengers || [];

    // Broadcast emergency alert
    io.emit('emergency-alert', {
      alertId: alertRef.id,
      tripId,
      routeId: tripData.routeId,
      routeName: route.data()?.name,
      routeNumber: route.data()?.routeNumber || tripData.routeId,
      vehicleId: tripData.vehicleId,
      alertType,
      message,
      location: location || tripData.currentLocation,
      timestamp: new Date()
    });

    // In production: Send FCM push notifications to affected passengers
    console.log(`🚨 Emergency alert created: ${alertRef.id} on trip ${tripId}`);

    res.status(200).json({
      success: true,
      alertId: alertRef.id,
      message: 'Emergency alert broadcast to passengers'
    });

  } catch (error) {
    console.error('Emergency alert error:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

app.get('/api/alerts/active', async (req, res) => {
  try {
    const snapshot = await db.collection('emergencyAlerts').where('status', '==', 'active').get();
    const alerts = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      location: mapCurrentLocation(doc.data().location),
      createdAt: doc.data().createdAt?.toDate?.().toISOString?.() || null,
    }));
    res.json({ success: true, alerts });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

app.post('/api/alerts/:alertId/resolve', verifyToken, async (req, res) => {
  try {
    const { alertId } = req.params;

    const alert = await db.collection('emergencyAlerts').doc(alertId).get();
    if (!alert.exists) {
      return res.status(404).json({ success: false, error: 'Alert not found' });
    }

    await db.collection('emergencyAlerts').doc(alertId).update({
      status: 'resolved',
      resolvedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Update trip
    const tripId = alert.data().tripId;
    await db.collection('liveTrips').doc(tripId).update({
      emergencyAlertActive: false
    });

    io.emit('alert-resolved', {
      alertId,
      tripId,
      timestamp: new Date()
    });

    res.json({ success: true, message: 'Alert resolved' });

  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

// ============================================
// 6. SEARCH & ROUTE INSIGHTS
// ============================================

app.post('/api/search/routes', async (req, res) => {
  try {
    const { startStop, endStop } = req.body;

    if (!startStop || !endStop) {
      return res.status(400).json({ 
        success: false, 
        error: 'startStop and endStop required' 
      });
    }

    const normalizeSearch = (value) => String(value).toLowerCase().replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();
    const startQuery = normalizeSearch(startStop);
    const endQuery = normalizeSearch(endStop);
    const routes = await db.collection('routes').get();
    const matchingRoutes = routes.docs.flatMap((doc) => {
      const route = normalizeRoute(doc.data());
      const stops = route.stops || [];
      const startIndex = stops.findIndex((stop) => normalizeSearch(stop.name).includes(startQuery));
      const endIndex = stops.findIndex((stop) => normalizeSearch(stop.name).includes(endQuery));
      if (startIndex === -1 || endIndex === -1 || startIndex === endIndex) return [];
      return [{ id: doc.id, ...route, direction: startIndex < endIndex ? 'outbound' : 'inbound' }];
    });

    // Get active trips for matching routes
    const routeResults = await Promise.all(
      matchingRoutes.map(async (route) => {
        const activeTrips = await db.collection('liveTrips').where('routeId', '==', route.id).get();

        return {
          route,
          activeTrips: activeTrips.docs
            .filter((doc) => isTripLive(doc.data()) && (doc.data().direction || 'outbound') === route.direction)
            .map((doc) => serializeTrip(doc.id, doc.data(), route))
        };
      })
    );

    res.json({ 
      success: true, 
      results: routeResults 
    });

  } catch (error) {
    console.error('Route search error:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

app.get('/api/routes/:routeId/insights', async (req, res) => {
  try {
    const { routeId } = req.params;

    // Get route
    const route = await db.collection('routes').doc(routeId).get();
    if (!route.exists) {
      return res.status(404).json({ success: false, error: 'Route not found' });
    }

    // Get completed trips from last 7 days
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const completedTrips = await db.collection('completedTrips')
      .where('routeId', '==', routeId)
      .where('completedAt', '>=', sevenDaysAgo)
      .get();

    // Calculate insights
    let totalTrips = completedTrips.size;
    let averageDuration = 0;
    let averageCrowdLevel = { available: 0, standing: 0, full: 0 };
    let onTimeTrips = 0;

    completedTrips.forEach(doc => {
      const data = doc.data();
      const duration = (data.endTime?.toMillis?.() - data.startTime?.toMillis?.()) / (1000 * 60);
      averageDuration += duration;

      const crowdData = data.crowdLevel;
      if (crowdData === 'available') averageCrowdLevel.available++;
      else if (crowdData === 'standing') averageCrowdLevel.standing++;
      else if (crowdData === 'full') averageCrowdLevel.full++;

      // Check if on time
      if (duration <= route.data().estimatedDurationMinutes * 1.1) {
        onTimeTrips++;
      }
    });

    averageDuration = totalTrips > 0 ? Math.round(averageDuration / totalTrips) : 0;

    res.json({
      success: true,
      insights: {
        routeName: route.data().name,
        totalTripsLastWeek: totalTrips,
        averageDurationMinutes: averageDuration,
        onTimeProbability: totalTrips > 0 ? Math.round((onTimeTrips / totalTrips) * 100) : 0,
        crowdDistribution: averageCrowdLevel,
        peakHours: route.data().peakHours || 'Not available',
        averagePassengers: route.data().averagePassengers || 'Not available'
      }
    });

  } catch (error) {
    console.error('Route insights error:', error);
    res.status(400).json({ success: false, error: error.message });
  }
});

// ============================================
// 7. USER PROFILE ENDPOINTS
// ============================================

app.get('/api/users/:userId', verifyToken, async (req, res) => {
  try {
    const { userId } = req.params;

    // Users can only view their own profile unless admin
    if (req.user.uid !== userId && req.user.role !== 'admin') {
      return res.status(401).json({ 
        success: false, 
        error: 'Not authorized' 
      });
    }

    const user = await db.collection('users').doc(userId).get();
    if (!user.exists) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    res.json({ 
      success: true, 
      user: {
        id: userId,
        ...user.data()
      }
    });

  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

app.put('/api/users/:userId/profile', verifyToken, async (req, res) => {
  try {
    const { userId } = req.params;
    const { fullName, phone, preferences } = req.body;

    if (req.user.uid !== userId) {
      return res.status(401).json({ success: false, error: 'Not authorized' });
    }

    const updateData = {};
    if (fullName) updateData.fullName = fullName;
    if (phone) updateData.phone = phone;
    if (preferences) updateData.preferences = preferences;

    await db.collection('users').doc(userId).update(updateData);

    res.json({ success: true, message: 'Profile updated' });

  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

// ============================================
// 8. ADMIN ANALYTICS ENDPOINTS
// ============================================

app.get('/api/admin/dashboard', verifyToken, async (req, res) => {
  try {
    // Verify admin role
    const user = await db.collection('users').doc(req.user.uid).get();
    if (!user.exists || user.data().role !== 'admin') {
      return res.status(401).json({ 
        success: false, 
        error: 'Admin access required' 
      });
    }

    // Get active trips
    const activeTrips = await db.collection('liveTrips')
      .where('status', '==', 'active')
      .get();

    // Get completed trips from today
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const completedToday = await db.collection('completedTrips')
      .where('completedAt', '>=', today)
      .get();

    // Get emergency alerts from today
    const emergencyAlertsToday = await db.collection('emergencyAlerts')
      .where('createdAt', '>=', today)
      .get();

    // Get total users
    const totalUsers = await db.collection('users').get();

    res.json({
      success: true,
      dashboard: {
        activeTripsCount: activeTrips.size,
        completedTripsToday: completedToday.size,
        emergencyAlertsToday: emergencyAlertsToday.size,
        totalUsers: totalUsers.size,
        activeTrips: activeTrips.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        }))
      }
    });

  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

app.get('/api/admin/analytics/routes', verifyToken, async (req, res) => {
  try {
    const user = await db.collection('users').doc(req.user.uid).get();
    if (!user.exists || user.data().role !== 'admin') {
      return res.status(401).json({ 
        success: false, 
        error: 'Admin access required' 
      });
    }

    const routes = await db.collection('routes').get();
    const routeAnalytics = [];

    for (const routeDoc of routes.docs) {
      const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      const trips = await db.collection('completedTrips')
        .where('routeId', '==', routeDoc.id)
        .where('completedAt', '>=', sevenDaysAgo)
        .get();

      routeAnalytics.push({
        routeId: routeDoc.id,
        routeName: routeDoc.data().name,
        tripsLastWeek: trips.size,
        avgCrowdLevel: 'medium'
      });
    }

    res.json({ success: true, analytics: routeAnalytics });

  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

// ============================================
// 9. HEALTH CHECK & STATUS
// ============================================

app.get('/api/health', async (req, res) => {
  try {
    // Check Firebase connection
    await db.collection('users').limit(1).get();

    res.json({
      success: true,
      status: 'healthy',
      server: 'TransitLive Pro Backend',
      timestamp: new Date(),
      firebaseConnected: true
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      status: 'unhealthy',
      error: error.message
    });
  }
});

app.get('/api/status', (req, res) => {
  res.json({
    success: true,
    status: 'running',
    server: 'TransitLive Pro Backend',
    port: PORT,
    environment: process.env.NODE_ENV || 'development',
    websocket: 'connected',
    timestamp: new Date()
  });
});

// ============================================
// 10. WEBSOCKET EVENTS (REAL-TIME)
// ============================================

io.on('connection', (socket) => {
  console.log(`👤 Client connected: ${socket.id}`);

  // Subscribe to trip updates
  socket.on('subscribe-trip', (tripId) => {
    socket.join(`trip-${tripId}`);
    console.log(`📍 Client subscribed to trip: ${tripId}`);
  });

  // Subscribe to route updates
  socket.on('subscribe-route', (routeId) => {
    socket.join(`route-${routeId}`);
    console.log(`🚌 Client subscribed to route: ${routeId}`);
  });

  // Disconnect handling
  socket.on('disconnect', () => {
    console.log(`👤 Client disconnected: ${socket.id}`);
  });
});

// ============================================
// 11. ERROR HANDLING & SERVER START
// ============================================

app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    path: req.path
  });
});

// ============================================
// SEED INITIAL ROUTES (runs once on startup)
// ============================================

async function seedRoutes() {
  try {
    const existing = await db.collection('routes').limit(1).get();
    if (!existing.empty) {
      console.log('✅ Routes already seeded, skipping.');
      return;
    }

    const routes = [
      {
        routeNumber: '502',
        from: 'Galle',
        to: 'Hapugala',
        departureTime: '06:00 AM',
        arrivalTime: '06:45 AM',
        stops: [
          { name: 'Galle Fort', lat: 6.0269, lng: 80.2168 },
          { name: 'Karapitiya Junction', lat: 6.0387, lng: 80.2134 },
          { name: 'Wakwella Road', lat: 6.0465, lng: 80.2098 },
          { name: 'Boossa', lat: 6.0512, lng: 80.2056 },
          { name: 'Hapugala', lat: 6.0580, lng: 80.2012 },
        ],
        distance: '28 km',
        fare: 'Rs. 45',
        frequency: 'Every 15 mins',
        active: true,
      },
      {
        routeNumber: '503',
        from: 'Galle',
        to: 'Matara',
        departureTime: '07:00 AM',
        arrivalTime: '08:30 AM',
        stops: [
          { name: 'Galle Bus Stand', lat: 6.0329, lng: 80.2168 },
          { name: 'Unawatuna', lat: 6.0099, lng: 80.2467 },
          { name: 'Koggala', lat: 5.9936, lng: 80.3003 },
          { name: 'Ahangama', lat: 5.9768, lng: 80.3618 },
          { name: 'Weligama', lat: 5.9735, lng: 80.4290 },
          { name: 'Matara', lat: 5.9549, lng: 80.5550 },
        ],
        distance: '42 km',
        fare: 'Rs. 65',
        frequency: 'Every 20 mins',
        active: true,
      },
      {
        routeNumber: '504',
        from: 'Galle',
        to: 'Colombo',
        departureTime: '08:00 AM',
        arrivalTime: '11:00 AM',
        stops: [
          { name: 'Galle Bus Stand', lat: 6.0329, lng: 80.2168 },
          { name: 'Hikkaduwa', lat: 6.1399, lng: 80.1054 },
          { name: 'Ambalangoda', lat: 6.2345, lng: 80.0546 },
          { name: 'Aluthgama', lat: 6.4267, lng: 79.9964 },
          { name: 'Kalutara', lat: 6.5854, lng: 79.9607 },
          { name: 'Panadura', lat: 6.7133, lng: 79.9042 },
          { name: 'Colombo Fort', lat: 6.9271, lng: 79.8612 },
        ],
        distance: '118 km',
        fare: 'Rs. 150',
        frequency: 'Every 30 mins',
        active: true,
      },
      {
        routeNumber: '505',
        from: 'Galle',
        to: 'Unawatuna',
        departureTime: '06:30 AM',
        arrivalTime: '07:00 AM',
        stops: [
          { name: 'Galle Fort', lat: 6.0269, lng: 80.2168 },
          { name: 'Light House', lat: 6.0180, lng: 80.2290 },
          { name: 'Unawatuna Beach', lat: 6.0099, lng: 80.2467 },
        ],
        distance: '6 km',
        fare: 'Rs. 20',
        frequency: 'Every 10 mins',
        active: true,
      },
      {
        routeNumber: '506',
        from: 'Galle',
        to: 'Kandy',
        departureTime: '05:30 AM',
        arrivalTime: '09:30 AM',
        stops: [
          { name: 'Galle Bus Stand', lat: 6.0329, lng: 80.2168 },
          { name: 'Elpitiya', lat: 6.2868, lng: 80.1684 },
          { name: 'Ratnapura', lat: 6.6828, lng: 80.3992 },
          { name: 'Avissawella', lat: 6.9526, lng: 80.2119 },
          { name: 'Kandy City', lat: 7.2906, lng: 80.6337 },
        ],
        distance: '155 km',
        fare: 'Rs. 200',
        frequency: 'Every 60 mins',
        active: true,
      },
    ];

    const batch = db.batch();
    for (const route of routes) {
      const ref = db.collection('routes').doc();
      batch.set(ref, { ...route, createdAt: new Date() });
    }
    await batch.commit();
    console.log(`✅ Seeded ${routes.length} routes into Firestore.`);
  } catch (err) {
    console.error('❌ Route seeding failed:', err.message);
  }
}

// Start server
server.listen(PORT, '0.0.0.0', async () => {
  const localIpAddress = getLocalIpAddress();
  console.log(`
╔════════════════════════════════════════╗
║   🚀 TransitLive Pro Backend Started   ║
╠════════════════════════════════════════╣
║  Server: http://${localIpAddress}:${PORT}              ║
║  WebSocket: ws://${localIpAddress}:${PORT}             ║
║  Firebase: Connected & Ready            ║
║  Mode: ${process.env.NODE_ENV || 'development'}                       ║
╚════════════════════════════════════════╝
  `);
  await seedRoutes();
});

module.exports = { app, io };
