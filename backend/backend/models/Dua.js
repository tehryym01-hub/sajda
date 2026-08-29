import mongoose from 'mongoose';

const duaSchema = new mongoose.Schema({
  category: {
    type: String,
    required: true,
    enum: ['morning', 'evening', 'sleep', 'food', 'travel', 'hardship', 'forgiveness', 'protection', 'ramadan'],
  },
  title: {
    en: { type: String, required: true },
    ur: { type: String, required: true },
  },
  arabic: { type: String, required: true },
  urdu: { type: String, required: true },
  english: { type: String, required: true },
  transliteration: { type: String, required: true },
  reference: { type: String, default: '' },
}, { timestamps: true });

duaSchema.index({ category: 1 });

export default mongoose.model('Dua', duaSchema);
