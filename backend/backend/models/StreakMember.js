import mongoose from 'mongoose';

const streakMemberSchema = new mongoose.Schema({
  streakId: { type: mongoose.Schema.Types.ObjectId, ref: 'SharedStreak', required: true, index: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  displayName: { type: String, required: true },
  joinedAt: { type: Date, default: Date.now },
  status: { 
    type: String, 
    enum: ['active', 'left', 'removed'], 
    default: 'active' 
  },
  currentDay: { type: Number, default: 0, min: 0 },
  lastCompletedDate: { type: String },
  notificationOptIn: { type: Boolean, default: true },
}, { timestamps: true });

streakMemberSchema.index({ streakId: 1, userId: 1 }, { unique: true });
streakMemberSchema.index({ streakId: 1, status: 1 });

export default mongoose.model('StreakMember', streakMemberSchema);