import mongoose from 'mongoose';

const wazifaSchema = new mongoose.Schema({
  dayOfYear: { type: Number, required: true, unique: true },
  title: {
    en: { type: String, required: true },
    ur: { type: String, required: true },
  },
  arabic: { type: String, default: '' },
  urdu: { type: String, required: true },
  english: { type: String, required: true },
  transliteration: { type: String, default: '' },
  count: { type: Number, default: 1 },
  type: { type: String, enum: ['dhikr', 'dua', 'amal', 'surah'], default: 'dhikr' },
  benefit: {
    en: { type: String, default: '' },
    ur: { type: String, default: '' },
  },
}, { timestamps: true });

wazifaSchema.index({ dayOfYear: 1 });

export default mongoose.model('Wazifa', wazifaSchema);
