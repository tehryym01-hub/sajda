import admin from 'firebase-admin';

import PushToken from '../models/PushToken.js';

// FCM is OPTIONAL infrastructure: when FIREBASE_SERVICE_ACCOUNT is absent
// (or malformed) every send is a silent no-op. The streak system NEVER
// depends on push — prayer completion succeeds regardless of token state.
let messaging = null;

try {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (raw) {
    const creds = typeof raw === 'string' ? JSON.parse(raw) : raw;
    admin.initializeApp({ credential: admin.credential.cert(creds) });
    messaging = admin.messaging();
    console.log('[FCM] enabled');
  }
} catch (e) {
  console.warn('[FCM] disabled — invalid FIREBASE_SERVICE_ACCOUNT:', e.message);
}

export const fcmEnabled = () => !!messaging;

// Fire-and-forget multicast to every device registered by these users.
// NEVER throws into the caller's flow (the prayer tick must not fail).
export const pushToUsers = async (userIds, { title, body, data = {} }) => {
  if (!messaging || !userIds || userIds.length === 0) return;
  try {
    const rows = await PushToken.find({ userId: { $in: userIds } }).lean();
    const tokens = [...new Set(rows.map((r) => r.token))];
    if (tokens.length === 0) return;
    const stringData = Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)]),
    );
    await messaging.sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: stringData,
      android: { priority: 'high' },
    });
  } catch (e) {
    console.warn('[FCM] send failed:', e.message);
  }
};
