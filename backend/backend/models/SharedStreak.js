import mongoose from 'mongoose';

const sharedStreakSchema = new mongoose.Schema({
  creatorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  title: { type: String, default: 'Salah Streak' },
  goalDays: { type: Number, required: true, min: 3, max: 365 },
  currentDay: { type: Number, default: 0, min: 0 },
  startDate: { type: Date, required: true },
  endDate: { type: Date },
  status: {
    type: String,
    enum: ['pending', 'active', 'completed', 'expired', 'cancelled'],
    default: 'pending'
  },
  inviteCode: { type: String, required: true, unique: true, index: true },
  maxMembers: { type: Number, default: 10, min: 2, max: 50 },
  isRevoked: { type: Boolean, default: false },
  completedAt: { type: Date },
}, { timestamps: true });

sharedStreakSchema.index({ creatorId: 1, status: 1 });
sharedStreakSchema.index({ inviteCode: 1 });

export default mongoose.model('SharedStreak', sharedStreakSchema);