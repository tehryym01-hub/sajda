import mongoose from 'mongoose';

const userSchema = new mongoose.Schema({
  displayName: { type: String, required: true, trim: true, maxlength: 100 },
  timezone: { type: String, default: 'Asia/Karachi' },
  city: { type: String, default: '' },
  country: { type: String, default: '' },
  deviceId: { type: String, unique: true, sparse: true, index: true },
}, { timestamps: true });

userSchema.index({ displayName: 1 });

export default mongoose.model('User', userSchema);
