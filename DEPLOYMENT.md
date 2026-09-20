# Deployment Guide — Sajda App

> Ye guide aaj ke (Sep 20, 2026) kaamyaab deployment se banayi gayi hai.
> Har cheez jo neeche hai wo **asli mein test aur chal** chuki hai.

---

## 1. Kya kahan deploy hota hai?

| Cheez | Kahan jati hai | Kaise |
|---|---|---|
| **Backend** (`/backend` folder, Node.js) | **Railway** (project: `sajda-prod`) | GitHub `main` par push → **auto-deploy** (3-6 min) |
| **Flutter app** (Android) | **Play Console** | Local build → AAB upload → review |
| Frontend web | Kuch nahi | App hi sab kuch hai |

**Live backend URL:** `https://backend-production-04292.up.railway.app/api`
**Health check:** `GET /api/health` → `200` hona chahiye

---

## 2. Saved credentials & IDs

**Railway account:** tehryym01@gmail.com (workspace: tehryym01-hub's Projects)

**API token:** repo root ki `.railway_token` file mein hai.
- Ye file `.gitignore` mein hai — **GitHub par kabhi push nahi hogi** (token leak = poora account hack)
- `backend/.env` wala purana token **DEAD** hai — use mat karna

**IDs (constants — ye kabhi nahi badalte):**

| Cheez | ID |
|---|---|
| Workspace | `ea6d93be-f71f-4f4d-aafd-2edfd30b0cb1` |
| Project (sajda-prod) | `b9aafb99-a3b1-487c-bbe5-556f016536d9` |
| Environment (production) | `7034f999-8ac3-4c5b-b079-f59a5b582f64` |
| Service (backend) | `a0c5e65a-849c-4eba-b7d4-6f7b38ac84f2` |

**GraphQL endpoint (sirf ye wala chalega):**
```
https://backboard.railway.app/graphql/v2
```
> ⚠️ `/graphql` (bina v2) **404** deta hai. CLI (`railway up` etc.) token env var ke sath
> "Unauthorized" deta hai — **CLI use mat karo, seedha API scripts use karo.**

---

## 3. Ready-made scripts (repo mein maujood)

Repo: `scripts/railway/` — token khud `.railway_token` se parhte hain.

```powershell
# Naya deploy trigger karo (bina sha = latest commit)
node scripts/railway/deploy.mjs

# Kisi KHUS commit ko deploy karna ho to (sha = git rev-parse HEAD ka output)
node scripts/railway/deploy.mjs 80628665ee642d0d39936ff43dc4a8cba48f8ccc

# Recent deployments ki list
node scripts/railway/status.mjs

# Latest deployment ko SUCCESS/FAILED hone tak watch karo (~40s poll)
node scripts/railway/status.mjs --watch

# Kisi deployment ke logs (crash diagnose karne ke liye)
node scripts/railway/logs.mjs <deploymentId>     # short id (8 letters) bhi chalta hai
```

---

## 4. Flow A — Normal deployment (90% cases)

Backend change kiya? Bas:

```powershell
git add <files>
git commit -m "fix: ..."
git push origin main
```

1. GitHub integration **khud deploy shuru** kar deta hai (Railway dashboard → Deployments mein dikhega)
2. 3-6 minute wait
3. Verify:
```powershell
Invoke-WebRequest -Uri "https://backend-production-04292.up.railway.app/api/health" -UseBasicParsing
node scripts/railway/status.mjs
```
4. Jo endpoint change hua usay live URL par bhi test karo.

**Deploy push ke foran baad trigger karna ho** to explicit sha dein (Railway ka git
sync thora late ho sakta hai — warna wo PURANA commit redeploy kar deta hai):
```powershell
git rev-parse HEAD          # sha copy karo
node scripts/railway/deploy.mjs <sha>
node scripts/railway/status.mjs --watch
```

---

## 5. Deploy FAIL ho jaye to

- **Ghabrao mat:** fail hui deployment live app ko nahi badalti — **purana chalta rehta hai.**
- Logs dekho:
```powershell
node scripts/railway/status.mjs            # FAILED deployment ka id note karo
node scripts/railway/logs.mjs <id>         # asli error yahan hoti hai
```
- Fix karo → commit → push → phir se.

---

## 6. Troubleshooting — aaj ke asli sabak

| Masla | Wajah | Hal |
|---|---|---|
| `service unavailable` healthcheck attempts, deploy FAILED | Server boot par crash (e.g. kisi file ne aisa import kiya jo service export nahi karti) | `logs.mjs` — crash ka exact file/error dikhta hai |
| `CLI Unauthorized` despite token | Railway CLI token env var theek se nahi leta | CLI chhoro, scripts use karo |
| GraphQL `404` | Ghalat endpoint (`/graphql`) | `/graphql/v2` use karo |
| `Unknown argument "serviceId" on field "Query.deployments"` | Ghalat query shape | Deployments **environment(id) ke andar** se lo |
| `Field "meta" must not have a selection` | `meta` scalar hai, sub-fields nahi | Sirf `meta` likho, `meta { ... }` nahi |
| `Cannot query field "edges" on type "Log"` | `deploymentLogs` flat list deta hai | `{ message severity timestamp }` — edges nahi |
| Deploy SUCCESS par purana code live | `latestCommit: true` ne cached purana sha liya ("reason: redeploy") | Explicit `commitSha` pass karo |
| Local test mein server 30s tak kuch nahi karta | `connectDB()` pehle hoti hai — bina MongoDB ke wo ~30s timeout lagati hai | Wait karo ya local Mongo chalao; deploy se pehle `node --check` + import-graph test kaafi hai |

---

## 7. Flutter app release (Play Console)

```powershell
# 1. Version badlo (pubspec.yaml):  version: 1.0.3+4   (hamesha dono barhao)
# 2. Build
flutter build appbundle --release
# 3. Output: build\app\outputs\bundle\release\app-release.aab
# 4. Play Console → Production → Create release → AAB upload
```
Release ke pehle:
```powershell
flutter analyze
flutter test
```
> Note: Railway/Play Console ek doosre se koi taluq nahi — backend ka deploy
> review ke doran bhi safe hai, chal rahi build par asar nahi hota.

---

## 8. Naya Railway token banana (agar purana ghair-maujood ho jaye)

1. https://railway.com → login (tehryym01@gmail.com)
2. Workspace Settings → **Tokens** (ya Account Settings → API Tokens)
3. Naya token banao, copy karo
4. Repo root ki `.railway_token` file mein paste kar do — bas, scripts phir chalengi

---

## Quick cheat-sheet

```powershell
# Backend deploy (sab se common)
git push origin main
node scripts/railway/status.mjs --watch

# Health check
curl https://backend-production-04292.up.railway.app/api/health

# Crash hua? 
node scripts/railway/status.mjs
node scripts/railway/logs.mjs <id>

# App release
flutter analyze; flutter test; flutter build appbundle --release
```
