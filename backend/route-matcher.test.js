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
const search = (passengerLat, passengerLng, destinationLat, destinationLng) => findMatchingBuses({
  passengerLat, passengerLng, destinationLat, destinationLng,
  activeTrips: [{ id: 'test-trip', routeId: '502' }],
  routesById: new Map([['502', route]]),
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
