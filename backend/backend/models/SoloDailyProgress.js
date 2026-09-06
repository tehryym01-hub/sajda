import mongoose from 'mongoose';

// SOLO DAILY PROGRESS — one row per user per calendar dateKey.
// Unique (userId, dateKey) makes completion idempotent by construction.
const soloDailyProgressSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  dateKey: { type: String, required: true, index: true }, // YYYY-MM-DD in user's timezone
  fajr: { type: Boolean, default: false },
  dhuhr: { type: Boolean, default: false },
  asr: { type: Boolean, default: false },
  maghrib: { type: Boolean, default: false },
  isha: { type: Boolean, default: false },
  completedCount: { type: Number, default: 0, min: 0, max: 5 },
  isDayComplete: { type: Boolean, default: false },
  completedAt: { type: Date }, // when the 5th prayer completed
}, { timestamps: true });

soloDailyProgressSchema.index({ userId: 1, dateKey: 1 }, { unique: true });
soloDailyProgressSchema.index({ userId: 1, isDayComplete: 1, dateKey: 1 });

export default mongoose.model('SoloDailyProgress', soloDailyProgressSchema);
