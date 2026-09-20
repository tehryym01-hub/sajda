import mongoose from 'mongoose';

// One document per Quran ayah with a multi-language translations object.
// Seeded by scripts/translateContent.js from official AlQuran Cloud editions.
const ayatTranslationSchema = new mongoose.Schema(
  {
    surah: { type: Number, required: true, min: 1, max: 114 },
    ayah: { type: Number, required: true, min: 1 },
    arabic: { type: String, required: true },
    translations: {
      ar: { type: String, default: '' },
      ur: { type: String, default: '' },
      en: { type: String, default: '' },
      hi: { type: String, default: '' },
      id: { type: String, default: '' },
    },
    source: { type: String, default: 'alquran.cloud' },
  },
  { timestamps: true }
);

ayatTranslationSchema.index({ surah: 1, ayah: 1 }, { unique: true });

export default mongoose.model('AyatTranslation', ayatTranslationSchema);
