const KAABA = { lat: 21.4225, lng: 39.8262 };

export const calculateQibla = (userLat, userLng) => {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const toDeg = (rad) => (rad * 180) / Math.PI;

  const lat1 = toRad(userLat);
  const lat2 = toRad(KAABA.lat);
  const dLng = toRad(KAABA.lng - userLng);

  const y = Math.sin(dLng) * Math.cos(lat2);
  const x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLng);
  let bearing = toDeg(Math.atan2(y, x));
  bearing = (bearing + 360) % 360;

  const direction = getDirectionName(bearing);

  const distance = calculateDistance(userLat, userLng, KAABA.lat, KAABA.lng);

  return {
    degree: Math.round(bearing),
    direction,
    distance: Math.round(distance),
  };
};

const getDirectionName = (bearing) => {
  const directions = [
    { min: 337.5, max: 360, name: 'North' },
    { min: 0, max: 22.5, name: 'North' },
    { min: 22.5, max: 67.5, name: 'North-East' },
    { min: 67.5, max: 112.5, name: 'East' },
    { min: 112.5, max: 157.5, name: 'South-East' },
    { min: 157.5, max: 202.5, name: 'South' },
    { min: 202.5, max: 247.5, name: 'South-West' },
    { min: 247.5, max: 292.5, name: 'West' },
    { min: 292.5, max: 337.5, name: 'North-West' },
  ];

  for (const d of directions) {
    if (d.min <= d.max) {
      if (bearing >= d.min && bearing < d.max) return d.name;
    } else {
      if (bearing >= d.min || bearing < d.max) return d.name;
    }
  }
  return 'North';
};

const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

export { KAABA };
