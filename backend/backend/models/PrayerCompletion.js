import mongoose from 'mongoose';

const prayerCompletionSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  date: { type: String, required: true, index: true }, // ISO date string YYYY-MM-DD in user's timezone
  fajr: { type: Boolean, default: false },
  dhuhr: { type: Boolean, default: false },
  asr: { type: Boolean, default: false },
  maghrib: { type: Boolean, default: false },
  isha: { type: Boolean, default: false },
  timezone: { type: String, required: true }, // IANA timezone e.g. 'Asia/Karachi'
  completedAt: { type: Map, of: Date }, // when each prayer was marked complete
  isComplete: { type: Boolean, default: false }, // all 5 prayers done
}, { timestamps: true });

prayerCompletionSchema.index({ userId: 1, date: 1 }, { unique: true });

export default mongoose.model('PrayerCompletion', prayerCompletionSchema);