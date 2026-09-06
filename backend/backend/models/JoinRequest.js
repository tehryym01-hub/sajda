import mongoose from 'mongoose';

// JOIN REQUESTS — one row per (group, user); the unique index prevents
// duplicate pending requests. Statuses: pending → approved/declined/cancelled.
const joinRequestSchema = new mongoose.Schema({
  groupId: { type: String, required: true, index: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  displayName: { type: String, required: true },
  status: { type: String, enum: ['pending', 'approved', 'declined', 'cancelled'], default: 'pending', index: true },
  decidedAt: { type: Date },
}, { timestamps: true });

joinRequestSchema.index({ groupId: 1, userId: 1 }, { unique: true });

export default mongoose.model('JoinRequest', joinRequestSchema);
