import mongoose from 'mongoose';

const manualNotificationSchema = new mongoose.Schema({
  title: { type: String, required: true },
  body: { type: String, default: '' },
  icon: { type: String, default: '/favicon.ico' },
  active: { type: Boolean, default: true },
}, { timestamps: true });

export default mongoose.model('ManualNotification', manualNotificationSchema);
