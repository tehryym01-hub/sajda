import mongoose from 'mongoose';

const userSchema = new mongoose.Schema({
  displayName: { type: String, required: true, trim: true, maxlength: 100 },
  timezone: { type: String, default: 'Asia/Karachi' },
  city: { type: String, default: '' },
  country: { type: String, default: '' },
  deviceId: { type: String, unique: true, sparse: true, index: true },
  // Firebase passwordless (magic link) identity. Streak data is bound to
  // the User doc these fields resolve to, so it survives reinstalls:
  // new device -> same email -> same firebaseUid -> same user.
  email: { type: String, unique: true, sparse: true, lowercase: true, trim: true },
  firebaseUid: { type: String, unique: true, sparse: true, index: true },
  notificationsSeenAt: { type: Date }, // in-app streak notification read marker (v2 streak)
}, { timestamps: true });

userSchema.index({ displayName: 1 });

export default mongoose.model('User', userSchema);
