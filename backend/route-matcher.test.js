const test = require('node:test');
const assert = require('node:assert/strict');
const { findMatchingBuses, normalizeRoute } = require('./route-matcher');

const route = {
  startPoint: 'Galle Bus Stand', endPoint: 'Hapugala Junction',
  stops: [
    { name: 'Galle Bus Stand', latitude: 6.0329, longitude: 80.2168 },
    { name: 'Hapugala Junction', latitude: 6.0645, longitude: 80.2261 },
  ],
};
const search = (passengerLat, passengerLng, destinationLat, destinationLng, trip = {}) => findMatchingBuses({
  passengerLat, passengerLng, destinationLat, destinationLng,
  activeTrips: [{ id: 'test-trip', routeId: '502', ...trip }],
  routesById: new Map([['502', route]]),
});
test('live GPS produces a pickup ETA and capacity', () => {
  const matches = search(6.0645, 80.2261, 6.0645, 80.2261, {
    currentLocation: { latitude: 6.0329, longitude: 80.2168 },
    currentSpeedKmh: 30,
    occupancy: 12,
    capacity: 40,
  });
  assert.equal(matches.length, 0, 'pickup and destination must be different ordered stops');

  const longerRoute = {
    ...route,
    stops: [
      route.stops[0],
      { name: 'Karapitiya', latitude: 6.0535, longitude: 80.2205 },
      route.stops[1],
    ],
  };
  const result = findMatchingBuses({
    passengerLat: 6.0535,
    passengerLng: 80.2205,
    destinationLat: 6.0645,
    destinationLng: 80.2261,
    activeTrips: [{ id: 'live', routeId: '502', currentLocation: { latitude: 6.0329, longitude: 80.2168 }, currentSpeedKmh: 30, capacity: 40 }],
    routesById: new Map([['502', longerRoute]]),
  });
  assert.equal(result.length, 1);
  assert.ok(result[0].etaMinutes > 0);
  assert.equal(result[0].capacity, 40);
});

test('seeded route names remain visible in the app', () => {
  assert.equal(normalizeRoute(route).from, 'Galle Bus Stand');
  assert.equal(normalizeRoute(route).to, 'Hapugala Junction');
  const matches = search(6.0329, 80.2168, 6.0645, 80.2261);
  assert.equal(matches.length, 1);
  assert.equal(matches[0].route.from, 'Galle Bus Stand');
});
test('no match for a distant pickup or reverse journey', () => {
  assert.equal(search(7, 80, 6.0645, 80.2261).length, 0);
  assert.equal(search(6.0645, 80.2261, 6.0329, 80.2168).length, 0);
});
test('an inbound driver trip matches the reverse stop direction', () => {
  const matches = search(6.0645, 80.2261, 6.0329, 80.2168, {
    direction: 'inbound',
    currentLocation: { latitude: 6.0645, longitude: 80.2261 },
  });
  assert.equal(matches.length, 1);
  assert.equal(matches[0].route.from, 'Hapugala Junction');
  assert.equal(matches[0].route.to, 'Galle Bus Stand');
});
