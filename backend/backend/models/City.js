import mongoose from 'mongoose';

const citySchema = new mongoose.Schema({
  name: { type: String, required: true },
  country: { type: String, required: true },
  coordinates: {
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
  },
  timezone: { type: String, required: true },
}, { timestamps: true });

citySchema.index({ name: 1, country: 1 }, { unique: true });

export default mongoose.model('City', citySchema);
