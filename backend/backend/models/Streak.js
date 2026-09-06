import mongoose from 'mongoose';

const streakSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  goalDays: { type: Number, required: true, min: 3, max: 365 },
  currentDay: { type: Number, default: 0, min: 0 },
  currentStreak: { type: Number, default: 0, min: 0 },
  longestStreak: { type: Number, default: 0, min: 0 },
  startDate: { type: Date, required: true },
  endDate: { type: Date },
  status: {
    type: String,
    enum: ['active', 'completed', 'paused', 'expired', 'cancelled'],
    default: 'active'
  },
  isShared: { type: Boolean, default: false },
  sharedStreakId: { type: mongoose.Schema.Types.ObjectId, ref: 'SharedStreak' },
  lastCompletedDate: { type: String }, // ISO date string
  streakHistory: [{
    date: { type: String, required: true },
    isComplete: { type: Boolean, required: true },
    prayerCounts: { type: Number, min: 0, max: 5 }
  }],
}, { timestamps: true });

streakSchema.index({ userId: 1, status: 1 });
streakSchema.index({ userId: 1, startDate: 1 });

export default mongoose.model('Streak', streakSchema);