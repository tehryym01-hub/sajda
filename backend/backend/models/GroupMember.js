import mongoose from 'mongoose';

// GROUP MEMBERSHIP — one row per (group, user), reused across
// leave/rejoin. `effectiveFromDate` is the first dateKey the member counts
// towards group completion (the day AFTER joining — new members never
// break an existing streak retroactively).
const groupMemberSchema = new mongoose.Schema({
  groupId: { type: String, required: true, index: true }, // Group.groupId
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  displayName: { type: String, required: true }, // snapshot for historical feeds
  role: { type: String, enum: ['owner', 'admin', 'member'], default: 'member' },
  status: { type: String, enum: ['active', 'left', 'removed'], default: 'active', index: true },
  joinedAt: { type: Date, default: Date.now },
  effectiveFromDate: { type: String, required: true }, // first dateKey that counts
  leftAt: { type: Date },
}, { timestamps: true });

groupMemberSchema.index({ groupId: 1, userId: 1 }, { unique: true });
groupMemberSchema.index({ groupId: 1, status: 1 });
groupMemberSchema.index({ userId: 1, status: 1 });

export default mongoose.model('GroupMember', groupMemberSchema);
