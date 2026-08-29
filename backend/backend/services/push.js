import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
dotenv.config({ path: join(dirname(fileURLToPath(import.meta.url)), '..', '..', '.env') });

import webpush from 'web-push';
import PushSubscription from '../models/PushSubscription.js';

const VAPID_PUBLIC_KEY = process.env.VAPID_PUBLIC_KEY;
const VAPID_PRIVATE_KEY = process.env.VAPID_PRIVATE_KEY;

webpush.setVapidDetails(
  process.env.VAPID_MAILTO || 'mailto:admin@sajdadailyathan\.site',
  VAPID_PUBLIC_KEY,
  VAPID_PRIVATE_KEY,
);

export function getVapidPublicKey() {
  return VAPID_PUBLIC_KEY;
}

export async function sendPush(subscription, title, body, data = {}) {
  try {
    const payload = JSON.stringify({ title, body, ...data });
    await webpush.sendNotification(subscription, payload);
    return true;
  } catch (err) {
    if (err.statusCode === 410 || err.statusCode === 404) {
      if (subscription?.endpoint) {
        await PushSubscription.deleteOne({ endpoint: subscription.endpoint });
      }
    }
    return false;
  }
}

export async function sendPushToAll(title, body, tag, soundDuration = 3) {
  const subs = await PushSubscription.find().lean();
  if (subs.length === 0) return { sent: 0, total: 0 };

  const results = await Promise.allSettled(
    subs.map((sub) => sendPush(sub.subscription, title, body, { tag, soundDuration }))
  );

  return { sent: results.filter(r => r.status === 'fulfilled' && r.value).length, total: subs.length };
}

export async function sendPushWazifa(wazifa) {
  const title = `🤲 Today's Wazifa: ${wazifa.title.en}`;
  const body = `${wazifa.english}\n\nCount: ${wazifa.count} times`;
  return sendPushToAll(title, body, 'push-wazifa', 5);
}

export async function sendPushManual(title, body) {
  return sendPushToAll(title, body, `push-manual-${Date.now()}`, 3);
}

