import express from 'express';
import PushSubscription from '../models/PushSubscription.js';
import { getVapidPublicKey } from '../services/push.js';

const router = express.Router();

router.get('/vapid-public-key', (req, res) => {
  res.json({ publicKey: getVapidPublicKey() });
});

router.post('/subscribe', async (req, res) => {
  try {
    const { subscription, type } = req.body;

    const existing = await PushSubscription.findOne({ endpoint: subscription.endpoint });
    if (existing) {
      existing.subscription = subscription;
      existing.type = type;
      await existing.save();
      return res.json({ success: true, message: 'Subscription updated' });
    }

    await PushSubscription.create({
      endpoint: subscription.endpoint,
      keys: subscription.keys || {},
      type,
      subscription,
    });
    res.status(201).json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false });
  }
});

router.delete('/unsubscribe', async (req, res) => {
  try {
    const { endpoint } = req.body;
    await PushSubscription.deleteOne({ endpoint });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false });
  }
});

export default router;
