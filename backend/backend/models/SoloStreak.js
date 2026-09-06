import mongoose from 'mongoose';

// SOLO STREAK — one per user. Streak values are DERIVED from
// solo_daily_progress records (never incremented by a tap) and refreshed
// on write/read. All timestamps UTC; day keys use the user's timezone.
const soloStreakSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true, index: true },
  status: { type: String, enum: ['active'], default: 'active' },
  currentStreak: { type: Number, default: 0, min: 0 },
  bestStreak: { type: Number, default: 0, min: 0 },
  currentStreakStartDate: { type: String }, // YYYY-MM-DD start of the current run
  lastCompletedDay: { type: String }, // YYYY-MM-DD last fully completed day
  lastEvaluatedDay: { type: String }, // last day the derived values were rolled forward
}, { timestamps: true });

export default mongoose.model('SoloStreak', soloStreakSchema);
