import mongoose from 'mongoose';

const pushSubscriptionSchema = new mongoose.Schema({
  type: { type: String, enum: ['owner', 'customer', 'user'], required: true },
  endpoint: { type: String, required: true, unique: true },
  keys: {
    p256dh: { type: String },
    auth: { type: String },
  },
  subscription: { type: mongoose.Schema.Types.Mixed },
  phone: { type: String, default: '' },
}, { timestamps: true });

export default mongoose.model('PushSubscription', pushSubscriptionSchema);
