import mongoose from 'mongoose';

const deletionRequestSchema = new mongoose.Schema({
  email: { type: String, required: true, lowercase: true, trim: true },
  phone: { type: String, default: '', trim: true },
  reason: { type: String, default: '' },
  details: { type: String, default: '', trim: true, maxlength: 2000 },
  status: { type: String, default: 'pending', enum: ['pending', 'processing', 'completed'] },
}, { timestamps: true });

deletionRequestSchema.index({ email: 1, createdAt: -1 });

export default mongoose.model('DeletionRequest', deletionRequestSchema);
