function haversineDistance(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function normalizeStops(stops) {
  if (!Array.isArray(stops)) return [];

  return stops
    .map((stop, index) => {
      const lat = typeof stop.lat === 'number' ? stop.lat : stop.latitude;
      const lng = typeof stop.lng === 'number' ? stop.lng : stop.longitude;

      if (typeof lat !== 'number' || typeof lng !== 'number') return null;

      return {
        name: stop.name || `Stop ${index + 1}`,
        lat,
        lng,
        order: typeof stop.order === 'number' ? stop.order : index + 1,
      };
    })
    .filter(Boolean)
    .sort((a, b) => a.order - b.order);
}

function findNearestStopIndex(stops, lat, lng, maxDistanceKm) {
  let nearestIndex = -1;
  let nearestDistance = Infinity;

  for (let i = 0; i < stops.length; i += 1) {
    const stop = stops[i];
    const distance = haversineDistance(lat, lng, stop.lat, stop.lng);

    if (distance <= maxDistanceKm && distance < nearestDistance) {
      nearestDistance = distance;
      nearestIndex = i;
    }
  }

  if (nearestIndex === -1) {
    return null;
  }

  return {
    index: nearestIndex,
    distanceKm: nearestDistance,
    stop: stops[nearestIndex],
  };
}

function mapCurrentLocation(currentLocation) {
  if (!currentLocation) return null;

  if (typeof currentLocation.latitude === 'number' && typeof currentLocation.longitude === 'number') {
    return {
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude,
    };
  }

  if (typeof currentLocation._latitude === 'number' && typeof currentLocation._longitude === 'number') {
    return {
      latitude: currentLocation._latitude,
      longitude: currentLocation._longitude,
    };
  }

  return null;
}

function normalizeRoute(route) {
  const stops = normalizeStops(route.stops);
  return {
    ...route,
    from: route.from || route.startPoint || stops[0]?.name || 'Unknown',
    to: route.to || route.endPoint || stops[stops.length - 1]?.name || 'Unknown',
  };
}

function findMatchingBuses({
  passengerLat,
  passengerLng,
  destinationLat,
  destinationLng,
  activeTrips,
  routesById,
  maxStopDistanceKm = 0.5,
}) {
  const matches = [];

  for (const trip of activeTrips) {
    const storedRoute = routesById.get(trip.routeId);
    if (!storedRoute) continue;
    const route = normalizeRoute(storedRoute);

    const stops = normalizeStops(route.stops);
    if (stops.length < 2) continue;

    const pickup = findNearestStopIndex(stops, passengerLat, passengerLng, maxStopDistanceKm);
    if (!pickup) continue;

    const remainingStops = stops.slice(pickup.index + 1);
    const destination = findNearestStopIndex(remainingStops, destinationLat, destinationLng, maxStopDistanceKm);
    if (!destination) continue;

    const destinationIndex = pickup.index + 1 + destination.index;

    matches.push({
      tripId: trip.id,
      routeId: trip.routeId,
      driverId: trip.driverId || null,
      vehicleId: trip.vehicleId || null,
      currentLocation: mapCurrentLocation(trip.currentLocation),
      occupancy: typeof trip.occupancy === 'number' ? trip.occupancy : 0,
      crowdLevel: trip.crowdLevel || 'unknown',
      pickupDistanceKm: Number(pickup.distanceKm.toFixed(3)),
      destinationDistanceKm: Number(destination.distanceKm.toFixed(3)),
      pickupStop: {
        index: pickup.index,
        ...pickup.stop,
      },
      dropoffStop: {
        index: destinationIndex,
        ...stops[destinationIndex],
      },
      nextStops: stops.slice(pickup.index, destinationIndex + 1),
      route: {
        id: trip.routeId,
        routeNumber: route.routeNumber || trip.routeId,
        from: route.from || 'Unknown',
        to: route.to || 'Unknown',
        stops,
        fare: route.fare || null,
        frequency: route.frequency || null,
      },
      trip: {
        id: trip.id,
        routeId: trip.routeId,
        vehicleId: trip.vehicleId || null,
        currentLocation: mapCurrentLocation(trip.currentLocation),
        occupancy: typeof trip.occupancy === 'number' ? trip.occupancy : 0,
        crowdLevel: trip.crowdLevel || 'unknown',
      },
    });
  }

  return matches.sort((a, b) => a.pickupDistanceKm - b.pickupDistanceKm);
}

module.exports = {
  findMatchingBuses,
  normalizeRoute,
};
