// ONE-TIME REPAIR for ghost streak data — the old deleteAccount only
// cleaned v1 collections, so deleted users stayed behind as:
//   - GroupMember rows in groups they can never come back to (a ghost
//     owner leaves the group ownerless and unmanageable)
//   - inflated Group.memberCount values (ghosts still counted)
//   - orphaned SoloStreak / SoloDailyProgress / PushToken rows
//
// What it does (idempotent — safe to run twice):
//   1. Removes every GroupMember row whose user no longer exists.
//   2. For each ACTIVE group left ownerless (owner user deleted):
//        - transfers ownership to an admin, else the oldest real member
//          (OWNER_OVERRIDES below wins when set)
//        - archives the group when no real member is left.
//   3. Deletes ghost SoloStreak / SoloDailyProgress / PushToken rows.
//   4. Recomputes memberCount from real active members.
//
// Usage (from the backend/ directory):
//   node backend/scripts/repairGhostMembers.js                     → dry run (default)
//   node backend/scripts/repairGhostMembers.js --apply             → write fixes
//   node backend/scripts/repairGhostMembers.js --db test --apply   → target the PRODUCTION db
//     (the local .env URI points at sajda_local_test; production data
//      lives in the `test` db on the same cluster — --db swaps the path)

import '../config/env.js';
import mongoose from 'mongoose';
import User from '../models/User.js';
import SoloStreak from '../models/SoloStreak.js';
import SoloDailyProgress from '../models/SoloDailyProgress.js';
import Group from '../models/Group.js';
import GroupMember from '../models/GroupMember.js';
import PushToken from '../models/PushToken.js';
import JoinRequest from '../models/JoinRequest.js';
import GroupDailyProgress from '../models/GroupDailyProgress.js';

const APPLY = process.argv.includes('--apply');
const DB_ARG_IDX = process.argv.indexOf('--db');
const FORCE_DB = DB_ARG_IDX >= 0 ? process.argv[DB_ARG_IDX + 1] : null;

// One-time production decision: youdoom8899@gmail.com created "Daily
// Namaz", lost the account row, and rejoined as a plain member — hand
// HIS group back to him regardless of membership seniority.
const OWNER_OVERRIDES = {
  grp_tcy5trxkmq: 'youdoom8899@gmail.com',
};

const stats = {
  ghostMemberRows: 0,
  ownershipTransfers: 0,
  groupsArchived: 0,
  memberCountsFixed: 0,
  ghostSoloStreaks: 0,
  ghostSoloProgress: 0,
  ghostPushTokens: 0,
  ghostJoinRequests: 0,
  ghostGroupProgress: 0,
};

const connect = async () => {
  if (!process.env.MONGODB_URI) {
    console.error('MONGODB_URI not configured — aborting.');
    process.exit(1);
  }
  let uri = process.env.MONGODB_URI;
  if (FORCE_DB) {
    uri = uri.replace(/^(mongodb(\+srv)?:\/\/[^/]+)\/[^?]*/, `$1/${FORCE_DB}`);
  }
  await mongoose.connect(uri, {
    serverSelectionTimeoutMS: 10000,
    socketTimeoutMS: 45000,
  });
  console.log(`Connected: ${mongoose.connection.host} / db: ${mongoose.connection.name}`);
  console.log(APPLY ? 'MODE: APPLY (writing fixes)\n' : 'MODE: DRY RUN (no writes)\n');
};

const run = async () => {
  await connect();
  const userIds = new Set();
  for await (const u of User.find({}).select('_id').lean()) userIds.add(String(u._id));
  const isGhost = (id) => !userIds.has(String(id));
  const emailByUser = new Map();
  for await (const u of User.find({}).select('email').lean()) {
    if (u.email) emailByUser.set(String(u._id), u.email.toLowerCase());
  }

  // ── 1) Ghost member rows ──
  const allMemberRows = await GroupMember.find({}).lean();
  const ghostRows = allMemberRows.filter((m) => isGhost(m.userId));
  const touchedGroups = new Set();
  for (const m of ghostRows) {
    touchedGroups.add(m.groupId);
    console.log(`ghost member row: group=${m.groupId} role=${m.role} user=${m.userId}`);
  }
  stats.ghostMemberRows = ghostRows.length;
  if (APPLY && ghostRows.length) {
    await GroupMember.deleteMany({ _id: { $in: ghostRows.map((m) => m._id) } });
  }

  // ── 2) Ownerless groups ──
  const ownerlessGroups = await Group.find({ status: 'active' }).lean();
  for (const g of ownerlessGroups) {
    if (!isGhost(g.ownerId)) continue;
    touchedGroups.add(g.groupId);
    const members = (await GroupMember.find({ groupId: g.groupId, status: 'active' })
      .sort({ createdAt: 1 }).lean())
      .filter((m) => !isGhost(m.userId)); // ghosts are leaving — never heirs
    const overrideEmail = OWNER_OVERRIDES[g.groupId];
    let heir = null;
    if (overrideEmail) {
      heir = members.find((m) => emailByUser.get(String(m.userId)) === overrideEmail) || null;
      if (!heir) console.log(`  !! override ${overrideEmail} not an active member of ${g.groupId}`);
    }
    if (!heir) heir = members.find((m) => m.role === 'admin') || members[0] || null;

    if (heir) {
      const heirUser = await User.findById(heir.userId).select('displayName email').lean();
      console.log(`transfer: group=${g.name} (${g.groupId}) -> ${heirUser?.email || heir.userId}`);
      stats.ownershipTransfers += 1;
      if (APPLY) {
        await Group.updateOne(
          { groupId: g.groupId },
          { $set: { ownerId: heir.userId } },
        );
        await GroupMember.updateOne({ _id: heir._id }, { $set: { role: 'owner' } });
      }
    } else {
      console.log(`archive: group=${g.name} (${g.groupId}) — no real member left`);
      stats.groupsArchived += 1;
      if (APPLY) {
        await Group.updateOne(
          { groupId: g.groupId },
          { $set: { status: 'archived', archivedAt: new Date() } },
        );
      }
    }
  }

  // ── 3) memberCount recompute for touched groups (real members only) ──
  for (const groupId of touchedGroups) {
    const g = await Group.findOne({ groupId }).lean();
    if (!g || g.status !== 'active') continue;
    const rows = await GroupMember.find({ groupId, status: 'active' }).select('userId').lean();
    const real = rows.filter((m) => !isGhost(m.userId)).length;
    if (real !== g.memberCount) {
      console.log(`memberCount: group=${g.name} ${g.memberCount} -> ${real}`);
      stats.memberCountsFixed += 1;
      if (APPLY) {
        await Group.updateOne({ groupId }, { $set: { memberCount: real } });
      }
    }
  }

  // ── 4) Ghost v2 rows ──
  const ghostUserIds = [...new Set(allMemberRows.filter((m) => isGhost(m.userId)).map((m) => m.userId))];
  // Widen the sweep: any row whose userId is not a live user.
  const allGhostIds = new Set();
  for (const Model of [SoloStreak, SoloDailyProgress, PushToken, JoinRequest, GroupDailyProgress]) {
    for await (const row of Model.find({}).select('userId').lean()) {
      if (isGhost(row.userId)) allGhostIds.add(String(row.userId));
    }
  }
  const ids = [...allGhostIds].map((x) => new mongoose.Types.ObjectId(x));
  if (ids.length) {
    stats.ghostSoloStreaks = await SoloStreak.countDocuments({ userId: { $in: ids } });
    stats.ghostSoloProgress = await SoloDailyProgress.countDocuments({ userId: { $in: ids } });
    stats.ghostPushTokens = await PushToken.countDocuments({ userId: { $in: ids } });
    stats.ghostJoinRequests = await JoinRequest.countDocuments({ userId: { $in: ids } });
    stats.ghostGroupProgress = await GroupDailyProgress.countDocuments({ userId: { $in: ids } });
    if (APPLY) {
      await Promise.all([
        SoloStreak.deleteMany({ userId: { $in: ids } }),
        SoloDailyProgress.deleteMany({ userId: { $in: ids } }),
        PushToken.deleteMany({ userId: { $in: ids } }),
        JoinRequest.deleteMany({ userId: { $in: ids } }),
        GroupDailyProgress.deleteMany({ userId: { $in: ids } }),
      ]);
    }
  }

  console.log('\n── Summary ──');
  console.log(JSON.stringify(stats, null, 2));
  if (!APPLY) console.log('\n(dry run — re-run with --apply to write)');
  await mongoose.disconnect();
};

run().catch((e) => {
  console.error('repair failed:', e);
  process.exit(1);
});
