import mongoose from 'mongoose';

const eventSchema = new mongoose.Schema({
  month: { type: String, required: true },
  monthNumber: { type: Number, required: true },
  day: { type: Number, required: true },
  title: {
    en: { type: String, required: true },
    ur: { type: String, required: true },
  },
  type: {
    type: String,
    enum: ['celebration', 'major_celebration', 'mourning', 'major_mourning', 'general'],
    default: 'general',
  },
  description: {
    en: { type: String, default: '' },
    ur: { type: String, default: '' },
  },
  amal: [{ type: String }],
  duas: [{
    arabic: String,
    urdu: String,
    transliteration: String,
  }],
}, { timestamps: true });

eventSchema.index({ monthNumber: 1, day: 1 });

export default mongoose.model('Event', eventSchema);
