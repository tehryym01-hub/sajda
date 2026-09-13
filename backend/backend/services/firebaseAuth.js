// Firebase ID token verification — dependency-free.
//
// Verifies RS256-signed Firebase Auth ID tokens against Google's public
// x509 certificates (https://www.googleapis.com/robot/v1/metadata/x509/
// securetoken@system.gserviceaccount.com). No service-account credentials
// are required for VERIFICATION — only the public project id.
//
// Security contract: this is the ONLY way a firebaseUid/email may enter the
// system. Callers must never trust client-sent uid/email without a verified
// token behind them.
import crypto from 'crypto';

const PROJECT_ID = () => process.env.FIREBASE_PROJECT_ID || 'sajda-b8dce';
const CERTS_URL =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';
const ISSUER = () => `https://securetoken.google.com/${PROJECT_ID()}`;

let certCache = { certs: null, fetchedAt: 0 };
const CERT_TTL_MS = 60 * 60 * 1000; // certs rotate hourly

async function publicCerts() {
  const fresh = certCache.certs && Date.now() - certCache.fetchedAt < CERT_TTL_MS;
  if (fresh) return certCache.certs;
  const res = await fetch(CERTS_URL);
  if (!res.ok) throw new Error('FIREBASE_CERTS_UNAVAILABLE');
  const certs = await res.json();
  certCache = { certs, fetchedAt: Date.now() };
  return certs;
}

export class FirebaseTokenError extends Error {
  constructor(code) {
    super(code);
    this.code = code;
  }
}

const b64urlJson = (segment) =>
  JSON.parse(Buffer.from(segment, 'base64url').toString('utf8'));

/// Verifies a Firebase ID token and returns its claims
/// ({ sub/user_id, email, email_verified, ... }).
export async function verifyFirebaseIdToken(idToken) {
  if (!idToken || typeof idToken !== 'string') {
    throw new FirebaseTokenError('MISSING_ID_TOKEN');
  }
  const parts = idToken.split('.');
  if (parts.length !== 3) throw new FirebaseTokenError('MALFORMED_TOKEN');

  let header;
  let claims;
  try {
    header = b64urlJson(parts[0]);
    claims = b64urlJson(parts[1]);
  } catch (_) {
    throw new FirebaseTokenError('MALFORMED_TOKEN');
  }
  if (header.alg !== 'RS256' || !header.kid) {
    throw new FirebaseTokenError('UNSUPPORTED_ALG');
  }

  const certs = await publicCerts();
  const pem = certs[header.kid];
  if (!pem) throw new FirebaseTokenError('UNKNOWN_KID');

  let verified = false;
  try {
    const key = new crypto.X509Certificate(pem).publicKey;
    verified = crypto
      .createVerify('RSA-SHA256')
      .update(`${parts[0]}.${parts[1]}`)
      .verify(key, Buffer.from(parts[2], 'base64url'));
  } catch (_) {
    throw new FirebaseTokenError('INVALID_SIGNATURE');
  }
  if (!verified) throw new FirebaseTokenError('INVALID_SIGNATURE');

  const now = Math.floor(Date.now() / 1000);
  if (typeof claims.exp !== 'number' || claims.exp <= now) {
    throw new FirebaseTokenError('TOKEN_EXPIRED');
  }
  if (typeof claims.iat !== 'number' || claims.iat > now + 300) {
    throw new FirebaseTokenError('INVALID_IAT');
  }
  if (typeof claims.auth_time !== 'number' || now - claims.auth_time > 86400) {
    // Token must come from a recent sign-in (magic link, etc.).
    throw new FirebaseTokenError('STALE_AUTH_TIME');
  }
  if (claims.aud !== PROJECT_ID()) throw new FirebaseTokenError('WRONG_AUDIENCE');
  if (claims.iss !== ISSUER()) throw new FirebaseTokenError('WRONG_ISSUER');
  if (!claims.sub || typeof claims.sub !== 'string') {
    throw new FirebaseTokenError('MISSING_SUBJECT');
  }

  return {
    uid: claims.sub,
    email: typeof claims.email === 'string' ? claims.email.toLowerCase() : '',
    emailVerified: claims.email_verified === true,
  };
}
