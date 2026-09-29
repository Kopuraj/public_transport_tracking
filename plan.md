# 📋 LIVE TRANSPORT TRACKING APP - BUILD PLAN

**Duration:** 3-4 weeks  
**Goal:** Transform current app into fully functional ride-matching + real-time tracking system  
**Start Date:** April 5, 2026

---

## 🎯 Overall Architecture Flow

```
Passenger: Enter Origin → Destination
    ↓
Backend: Match to Active Bus Routes
    ↓
Passenger: See Available Buses with ETA + Crowd
    ↓
Passenger: Click "Book Ticket"
    ↓
Driver: GPS Updates → Passenger sees live movement
    ↓
Driver: Update Crowd → Passenger sees occupancy change
```

---

# WEEK 1: Route Matching & Intelligent Bus Discovery

## 📌 Goal
Passengers can enter origin/destination and see **only relevant buses** (not all 5 routes).

### Backend Tasks

#### Task 1.1: Create route-matching endpoint
**File:** `backend/server.js`  
**Add endpoint:**
```
POST /api/routes/find-buses
Input: {
  passengerLat: number,
  passengerLng: number,
  destinationLat: number,
  destinationLng: number
}
Output: [
  {
    tripId: string,
    routeId: string,
    driverId: string,
    currentLat: number,
    currentLng: number,
    crowd: number,
    totalCapacity: number,
    nextStops: [{name, lat, lng}],
    estimatedArrival: timestamp (calculated)
  }
]
```

**Logic:**
- Get all active trips from `liveTrips` collection
- For each trip, get route details from `routes` collection
- Check if route passes within 500m of passenger's origin
- Check if route passes within 500m of passenger's destination
- Return matching trips with live data

**Distance function:** Use Haversine formula to calculate lat/lng distance
```javascript
function haversineDistance(lat1, lng1, lat2, lng2) {
  const R = 6371; // Earth radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}
```

#### Task 1.2: Add route-matching service
**New File:** `backend/route-matcher.js`
- Export function: `findMatchingBuses(passengerLat, passengerLng, destLat, destLng)`
- Check if passenger origin is within 500m of any route stop
- Check if destination is within 500m of any route stop after passenger pickup
- Return list of valid trips

#### Task 1.3: Database schema updates
**Firestore `routes` collection** (already seeded, verify structure):
```json
{
  "routeId": "502",
  "name": "Downtown → Airport",
  "stops": [
    {"name": "Central Station", "lat": 40.7128, "lng": -74.0060, "order": 1},
    {"name": "Bus Terminal", "lat": 40.7209, "lng": -74.0047, "order": 2}
  ]
}
```

**Firestore `liveTrips` collection** (already exists):
- Verify has: `tripId`, `routeId`, `driverId`, `currentLocation`, `crowd`, `capacity`, `status`

### Frontend Tasks

#### Task 1.4: Create origin/destination selection screen
**New File:** `lib/screens/find_bus_screen.dart`
- 2 map pickers: "Pickup location" + "Destination"
- Button: "Search Available Buses"
- Call API: `ApiService.findBuses(origin lat/lng, dest lat/lng)`
- Display results as list with:
  - Route name
  - Bus number (routeId)
  - Current location on map
  - Occupancy (crowd/capacity)
  - ETA to passenger (TBD in Week 2)

#### Task 1.5: Update trip selection flow
**File:** `lib/screens/trip_tracking_screen.dart`
- Replace current "Select Route" dropdown with call to new `FindBusScreen`
- Get matched buses from API instead of displaying all routes

#### Task 1.6: Add API method
**File:** `lib/services/api_service.dart`
```dart
Future<List<BusMatch>> findBuses(
  double passengerLat, 
  double passengerLng, 
  double destLat, 
  double destLng
) async {
  final response = await http.post(
    Uri.parse('$wsUrl/api/routes/find-buses'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'passengerLat': passengerLat,
      'passengerLng': passengerLng,
      'destinationLat': destLat,
      'destinationLng': destLng,
    }),
  );
  // Parse response into List<BusMatch>
}
```

### Testing Checklist - Week 1

- [ ] Backend returns 0 buses when no routes nearby
- [ ] Backend returns all 5 routes when passenger in city center
- [ ] Backend returns 2 routes when passenger near edges
- [ ] Frontend map pickers work (can set 2 locations)
- [ ] Frontend API call successful, displays results
- [ ] Real device test: Driver running trip, passenger searches, sees it
- [ ] Firebase Firestore routes collection has all stops properly structured

### Database Prep

**Run once on backend (add to seed-routes.js if not already present):**
```javascript
// Ensure routes have proper stop structure with lat/lng and order
db.collection('routes').add({
  routeId: '502',
  name: 'Downtown → Airport',
  stops: [
    {name: 'Central Station', lat: 40.7128, lng: -74.0060, order: 1},
    {name: 'Penn Station', lat: 40.7505, lng: -73.9972, order: 2},
    {name: 'Airport Terminal', lat: 40.7769, lng: -73.8740, order: 3}
  ]
});
```

---

# WEEK 2: ETA Calculation & Real-Time Arrival Estimates

## 📌 Goal
Show "Arrives in 12 minutes at your stop" on passenger dashboard.

### Backend Tasks

#### Task 2.1: Create ETA calculation endpoint
**File:** `backend/server.js`  
**Add endpoint:**
```
POST /api/trips/{tripId}/eta
Input: {
  passengerLat: number,
  passengerLng: number,
  pickupStopIndex: number  // which stop passenger boards at
}
Output: {
  estimatedSeconds: number,
  estimatedArrival: ISO timestamp,
  distance: number (km),
  currentDistance: number (km from driver to passenger)
}
```

**Logic:**
1. Get current driver location from `liveTrips[tripId].currentLocation`
2. Get passenger pickup point
3. Calculate distance: Driver → Passenger → Destination
4. Estimate speed: Use historical speed from `gpsHistory` OR assume 40 km/h average
5. Return ETA in seconds

#### Task 2.2: Distance calculation utility
**New File:** `backend/distance-calculator.js`
```javascript
function estimateETA(driverLat, driverLng, passengerLat, passengerLng, routeStops) {
  // Calculate distance via Haversine
  const distToPassenger = haversineDistance(
    driverLat, driverLng,
    passengerLat, passengerLng
  );
  
  // Get remaining route distance (sum of stop-to-stop distances on route)
  const remainingRouteDistance = calculateRouteSegment(routeStops);
  
  // Estimate speed from recent GPS history (km/h)
  const estimatedSpeed = 40; // fallback: 40 km/h average city speed
  
  // Total time = distance / speed
  const totalSeconds = (distToPassenger + remainingRouteDistance) / estimatedSpeed * 3600;
  
  return {
    estimatedSeconds: Math.round(totalSeconds),
    estimatedArrival: new Date(Date.now() + totalSeconds * 1000),
    distance: distToPassenger + remainingRouteDistance
  };
}
```

#### Task 2.3: Store GPS history for speed calculation
**File:** `backend/server.js` → GPS update handler
- When driver sends GPS, also store in `gpsHistory` collection:
```json
{
  "tripId": "trip-xyz",
  "driverId": "driver-123",
  "lat": 40.7128,
  "lng": -74.0060,
  "timestamp": ISOString,
  "speed": number (calculated as distance/time from previous point)
}
```

### Frontend Tasks

#### Task 2.4: Display ETA on bus card
**File:** `lib/screens/find_bus_screen.dart`
- Add to BusMatch widget:
  ```
  "Arrives in 12 min" (If passenger taps this bus)
  ```
- Call `ApiService.getETA(tripId, passengerLat, passengerLng)` on tap
- Store ETA and refresh every 10 seconds while screen open

#### Task 2.5: Update bus result card layout
**File:** `lib/widgets/bus_result_card.dart` (new widget)
```dart
Card(
  child: Column(
    children: [
      Text('Route ${bus.routeId}'),
      Text('${bus.crowd}/${bus.totalCapacity} passengers'),
      Text('ETA: ${etaMinutes} minutes'),  // NEW
      ElevatedButton('Book Now'),
    ],
  ),
)
```

#### Task 2.6: Add ETA API method
**File:** `lib/services/api_service.dart`
```dart
Future<ETAData> getETA(
  String tripId,
  double passengerLat,
  double passengerLng,
  int stopIndex
) async {
  final response = await http.post(
    Uri.parse('$wsUrl/api/trips/$tripId/eta'),
    body: jsonEncode({...})
  );
  return ETAData.fromJson(jsonDecode(response.body));
}
```

### Testing Checklist - Week 2

- [ ] ETA endpoint returns time in range 5-30 minutes for typical routes
- [ ] ETA updates every 5 seconds as driver moves (WebSocket push)
- [ ] ETA = 0 when driver reaches passenger pickup location
- [ ] gpsHistory collection has speed data after 5+ driver updates
- [ ] Frontend displays ETA as human-readable "Arrives in X minutes"
- [ ] ETA refreshes when WebSocket sends gps-update
- [ ] Real test: Start trip, request ETA, watch countdown as driver approaches

### Database Prep

**Create gpsHistory collection index (Firestore):**
```
Collection: gpsHistory
Fields: tripId, driverId, timestamp
Index: (tripId, timestamp) for fast queries
```

---

# WEEK 3: Booking System & Seat Reservation

## 📌 Goal
Passengers can book a seat, driver sees reservation, both get confirmation.

### Backend Tasks

#### Task 3.1: Create booking endpoint
**File:** `backend/server.js`
**Add endpoints:**

```
POST /api/bookings
Input: {
  passengerId: string,
  tripId: string,
  pickupStopIndex: number,
  dropoffStopIndex: number,
  passengerCount: number (1-4 people),
  estimatedFare: number (calculated)
}
Output: {
  bookingId: string,
  status: "confirmed",
  qrCode: string (for driver verification)
}
```

```
GET /api/bookings/{bookingId}
Output: { bookingId, status, tripId, fare, qrCode }
```

```
POST /api/trips/{tripId}/bookings
Output: [{ passengerId, count, pickupStop, dropoffStop }]
```

#### Task 3.2: Booking storage & validation
**New File:** `backend/booking-service.js`
- Before booking, verify:
  - Trip exists and is active
  - Requested seats available (crowd + request ≤ capacity)
  - Pickup/dropoff are valid stops on route
- Create `bookings` Firestore collection:
```json
{
  "bookingId": "booking-60a5e9d9",
  "passengerId": "user-123",
  "tripId": "trip-xyz",
  "passengerCount": 2,
  "pickupStop": 1,
  "dropoffStop": 3,
  "status": "confirmed",
  "fare": 2.50,
  "qrCode": "data:image/png;base64,...",
  "createdAt": timestamp
}
```

#### Task 3.3: Update trip capacity tracking
**File:** `backend/server.js` → liveTrips update
- When booking confirmed:
  - Deduct seats: `liveTrips[tripId].availableSeats -= passengerCount`
  - Update `crowd = capacity - availableSeats`
  - Broadcast `crowd-update` to subscribed passengers

#### Task 3.4: Generate QR code for driver verification
**Add dependency:** `npm install qrcode`
- In booking endpoint, generate QR code containing: `bookingId + passengerId + tripId`
- Driver app scans QR when passenger boards (Week 4 optional)

### Frontend Tasks

#### Task 3.5: Create booking confirmation screen
**New File:** `lib/screens/booking_confirmation_screen.dart`
- Display:
  - Route name & number
  - Pickup stop & time
  - Dropoff stop
  - Estimated fare
  - Passenger count (spinner 1-4)
  - Button: "Confirm Booking"
- Call `ApiService.createBooking(...)`
- Show confirmation with Booking ID + QR code

#### Task 3.6: Update FindBusScreen to show availability
**File:** `lib/screens/find_bus_screen.dart`
- Show available seats: `"12 seats available"` / `"Full"`
- Disable booking if full
- On "Book Now" → navigate to BookingConfirmationScreen

#### Task 3.7: Add booking API methods
**File:** `lib/services/api_service.dart`
```dart
Future<BookingConfirmation> createBooking({
  required String tripId,
  required int pickupStopIndex,
  required int dropoffStopIndex,
  required int passengerCount,
  required String passengerId,
}) async {
  // POST /api/bookings
}

Future<BookingDetails> getBookingDetails(String bookingId) async {
  // GET /api/bookings/{bookingId}
}
```

#### Task 3.8: Add booking status screen
**File:** `lib/screens/booking_status_screen.dart`
- Show after booking confirmation
- Display:
  - Booking ID
  - QR code (driver scans this)
  - "Waiting for driver..." message
  - Real-time ETA countdown
  - Driver current location on map
- Listen to WebSocket for driver approaching (gps-update → recalculate ETA)

### Testing Checklist - Week 3

- [ ] Can't book when trip full (availableSeats = 0)
- [ ] Booking deducts seats from trip (crowd updates)
- [ ] QR code generates correctly, contains all data
- [ ] Passenger sees booking confirmation with ID
- [ ] Booking stored in Firestore with status "confirmed"
- [ ] API returns existing booking when queried
- [ ] ETA updates real-time on booking status screen
- [ ] Real test: Driver starts trip (capacity 30), 2 passengers book 15 seats each, third can't book
- [ ] Real test: Driver moves on phone, passenger sees ETA countdown

### Database Prep

**Create bookings collection (Firestore):**
```
Collection: bookings
Fields: bookingId, passengerId, tripId, createdAt, status
Index: (tripId, createdAt) fast lookup
Index: (passengerId, status) passenger's active bookings
```

**Update trips capacity structure:**
```json
// liveTrips document
{
  "capacity": 30,
  "crowd": 15,
  "availableSeats": 15,  // NEW
  "bookings": [          // NEW - array of bookingIds
    "booking-60a5e9d9",
    "booking-60a5e9da"
  ]
}
```

---

# WEEK 4 (OPTIONAL): Payment & Polish

## 📌 Goal
Add payment processing and production-ready features.

### Payment Integration

#### Task 4.1: Add Razorpay (or Stripe) integration
- Add payment endpoint: `POST /api/payments/create-order`
- Frontend: Open payment dialog on booking
- Store payment status in booking record

#### Task 4.2: Handle failed bookings
- If payment fails, release seats: `availableSeats++`
- Notify driver of cancellation

### Performance & Polish

#### Task 4.3: Optimize real-time updates
- Batch socket broadcasts (group updates every 2-3 seconds)
- Reduce map re-renders with ChangeNotifier optimization

#### Task 4.4: Add user feedback
- Toast on successful booking / ETA update
- Loading indicators during API calls
- Error messages with retry buttons

#### Task 4.5: Create driver booking view
**New File:** `lib/screens/driver_bookings_screen.dart`
- Show list of confirmed bookings for current trip
- Display passenger count per booking
- Show QR code scanner for boarding verification

---

# 📊 Summary Timeline

| Week | Focus | Key Deliverable |
|------|-------|-----------------|
| 1 | Route Matching | Passengers can search & see relevant buses |
| 2 | ETA Calculation | "Arrives in 12 minutes" display |
| 3 | Booking System | Passengers can reserve seats |
| 4 | Payment + Polish | Production-ready app |

---

# ⚠️ Critical Prerequisites (Do Before Week 1)

- [ ] Backend running: `npm run dev` on 192.168.1.130:5000
- [ ] Frontend running: Driver on phone, Passenger on web
- [ ] All routes seeded in Firestore (5 routes with stops)
- [ ] WebSocket connection tested & stable
- [ ] Real-time GPS updates working (driver moves → passenger sees)

---

# 📝 Files to Create/Modify

### Backend
**Create:**
- `backend/route-matcher.js`
- `backend/distance-calculator.js`
- `backend/booking-service.js`

**Modify:**
- `backend/server.js` (add 4 new endpoints)

### Frontend
**Create:**
- `lib/screens/find_bus_screen.dart`
- `lib/screens/booking_confirmation_screen.dart`
- `lib/screens/booking_status_screen.dart`
- `lib/widgets/bus_result_card.dart`
- `lib/models/bus_match.dart`
- `lib/models/booking.dart`
- `lib/models/eta_data.dart`

**Modify:**
- `lib/screens/trip_tracking_screen.dart`
- `lib/services/api_service.dart`

---

# 🚀 How to Execute

**Each week:**
1. Read the tasks for that week
2. Implement backend endpoints first
3. Test with Postman/cURL before frontend
4. Build frontend screens
5. Run end-to-end test with real devices
6. Fix bugs before moving to next week

**No rushing.** Test thoroughly before advancing.

---

# 📞 Questions?

If any task is unclear or reveals dependencies, note them and adjust plan.

**Good luck! 🎯**
