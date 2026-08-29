import { calculateQibla } from '../services/qiblaService.js';

export const getQiblaDirection = (req, res, next) => {
  try {
    const { lat, lng } = req.query;

    if (!lat || !lng) {
      res.status(400);
      throw new Error('lat and lng query parameters are required');
    }

    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);

    if (isNaN(latitude) || isNaN(longitude)) {
      res.status(400);
      throw new Error('Invalid coordinates');
    }

    const qibla = calculateQibla(latitude, longitude);

    res.json({
      success: true,
      data: {
        ...qibla,
        userLocation: { lat: latitude, lng: longitude },
        kaabaLocation: { lat: 21.4225, lng: 39.8262 },
      },
    });
  } catch (error) {
    next(error);
  }
};
