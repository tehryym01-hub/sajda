import mongoose from 'mongoose';

// PUSH TOKENS — FCM-ready device registration. The streak system NEVER
// depends on these: prayer completion succeeds regardless of token state.
// When Firebase credentials are configured, the notification fan-out job
// delivers pending events to these tokens.
const pushTokenSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  token: { type: String, required: true },
  platform: { type: String, enum: ['android', 'ios', 'web'], default: 'android' },
}, { timestamps: true });

pushTokenSchema.index({ userId: 1, token: 1 }, { unique: true });

export default mongoose.model('PushToken', pushTokenSchema);
