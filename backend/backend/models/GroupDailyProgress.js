import mongoose from 'mongoose';

// GROUP DAILY PROGRESS — per member per group per dateKey.
// A member's progress is recorded even on their joining day (visible in
// the dashboard); `eligible` reflects whether this day counts towards the
// group completion requirement (effectiveFromDate <= dateKey).
const groupDailyProgressSchema = new mongoose.Schema({
  groupId: { type: String, required: true, index: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  dateKey: { type: String, required: true, index: true },
  fajr: { type: Boolean, default: false },
  dhuhr: { type: Boolean, default: false },
  asr: { type: Boolean, default: false },
  maghrib: { type: Boolean, default: false },
  isha: { type: Boolean, default: false },
  completedCount: { type: Number, default: 0, min: 0, max: 5 },
  isDayComplete: { type: Boolean, default: false },
  eligible: { type: Boolean, default: false },
  completedAt: { type: Date },
}, { timestamps: true });

groupDailyProgressSchema.index({ groupId: 1, userId: 1, dateKey: 1 }, { unique: true });
groupDailyProgressSchema.index({ groupId: 1, dateKey: 1, isDayComplete: 1 });

export default mongoose.model('GroupDailyProgress', groupDailyProgressSchema);
