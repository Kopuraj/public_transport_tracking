const admin = require('firebase-admin');
const serviceAccount = require('./firebase-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const routes = [
  {
    id: 'route_502',
    routeNumber: '502',
    name: 'Galle - Hapugala',
    startPoint: 'Galle Bus Stand',
    endPoint: 'Hapugala Junction',
    estimatedDurationMinutes: 45,
    stops: [
      { name: 'Galle Bus Stand', latitude: 6.0329, longitude: 80.2168 },
      { name: 'Karapitiya Junction', latitude: 6.0527, longitude: 80.2215 },
      { name: 'University Entrance', latitude: 6.0592, longitude: 80.2238 },
      { name: 'Hapugala Junction', latitude: 6.0645, longitude: 80.2261 }
    ]
  },
  {
    id: 'route_344',
    routeNumber: '344',
    name: 'Galle - Matara',
    startPoint: 'Galle Fort',
    endPoint: 'Matara City',
    estimatedDurationMinutes: 120,
    stops: [
      { name: 'Galle Fort', latitude: 6.0267, longitude: 80.2167 },
      { name: 'Unawatuna', latitude: 6.0123, longitude: 80.2456 },
      { name: 'Habaraduwa', latitude: 6.0012, longitude: 80.2987 },
      { name: 'Ahangama', latitude: 5.9765, longitude: 80.3654 },
      { name: 'Weligama', latitude: 5.9723, longitude: 80.4234 },
      { name: 'Matara City', latitude: 5.9432, longitude: 80.5432 }
    ]
  }
];

async function seedRoutes() {
  console.log('🌱 Seeding routes...');
  const batch = db.batch();

  for (const route of routes) {
    const routeRef = db.collection('routes').doc(route.id);
    batch.set(routeRef, {
      ...route,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }

  await batch.commit();
  console.log('✅ Routes seeded successfully!');
  process.exit(0);
}

seedRoutes().catch(err => {
  console.error('❌ Seeding failed:', err);
  process.exit(1);
});
