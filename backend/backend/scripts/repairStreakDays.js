// ONE-TIME REPAIR for the isDayComplete regression — days were being marked
// complete after a SINGLE prayer tick (markDayComplete used the request's
// `completed` flag instead of deriving from completedCount >= 5). That
// corrupted:
//   - solo_daily_progress / group_daily_progress rows (isDayComplete=true
//     with completedCount < 5)
//   - group_daily_summary rows (group days flipped complete too early)
//   - streak counters (SoloStreak / Group) derived from those rows
//
// Usage (from the backend/ directory):
//   node backend/scripts/repairStreakDays.js            → dry run (default)
//   node backend/scripts/repairStreakDays.js --apply    → write fixes
//
// The script is idempotent — safe to run twice.

import '../config/env.js';
import mongoose from 'mongoose';
import User from '../models/User.js';
import SoloStreak from '../models/SoloStreak.js';
import SoloDailyProgress from '../models/SoloDailyProgress.js';
import Group from '../models/Group.js';
import GroupMember from '../models/GroupMember.js';
import GroupDailyProgress from '../models/GroupDailyProgress.js';
import GroupDailySummary from '../models/GroupDailySummary.js';
import GroupActivity from '../models/GroupActivity.js';
import { todayKeyInTz } from '../services/streakLogic.js';
import {
  dayCompleteFromCount,
  isGroupDaySatisfied,
  currentRunFromDays,
  longestRunFromDays,
} from '../services/streakV2Logic.js';

const APPLY = process.argv.includes('--apply');

const stats = {
  soloRowsFixed: 0,
  groupRowsFixed: 0,
  groupDaysCompleted: 0,
  groupDaysReverted: 0,
  soloStreaksFixed: 0,
  groupsFixed: 0,
};

const connect = async () => {
  if (!process.env.MONGODB_URI) {
    console.error('MONGODB_URI not configured — aborting.');
    process.exit(1);
  }
  await mongoose.connect(process.env.MONGODB_URI, {
    serverSelectionTimeoutMS: 10000,
    socketTimeoutMS: 45000,
  });
  console.log(`Connected: ${mongoose.connection.host}`);
};

// ── Step 1 + 2: derive isDayComplete from completedCount on progress rows ──
const repairProgressRows = async (Model, label) => {
  const cursor = Model.find({}).cursor();
  const ops = [];
  for await (const row of cursor) {
    const shouldBeComplete = dayCompleteFromCount(row.completedCount);
    if (!!row.isDayComplete === shouldBeComplete) continue;
    const update = shouldBeComplete
      ? { $set: { isDayComplete: true, ...(row.completedAt ? {} : { completedAt: new Date() }) } }
      : { $set: { isDayComplete: false }, $unset: { completedAt: '' } };
    ops.push({ updateOne: { filter: { _id: row._id }, update } });
    stats[`${label}RowsFixed`]++;
  }
  if (APPLY && ops.length) await Model.bulkWrite(ops);
  console.log(`${label}: ${ops.length} rows to fix${APPLY ? ' — FIXED' : ' (dry run)'}`);
};

// ── Step 3: recompute every group-day summary from the FIXED member rows ──
const repairGroupSummaries = async () => {
  const groups = await Group.find({}).select('groupId timezone').lean();
  for (const group of groups) {
    const members = await GroupMember.find({ groupId: group.groupId, status: 'active' })
      .select('userId effectiveFromDate').lean();
    const summaries = await GroupDailySummary.find({ groupId: group.groupId }).lean();
    for (const summary of summaries) {
      const eligible = members.filter((m) => String(m.effectiveFromDate) <= String(summary.dateKey));
      const rows = await GroupDailyProgress.find({
        groupId: group.groupId, dateKey: summary.dateKey, eligible: true,
      }).select('userId isDayComplete').lean();
      const satisfied = isGroupDaySatisfied(eligible, rows);
      if (satisfied && !summary.isGroupDayComplete) {
        stats.groupDaysCompleted++;
        if (APPLY) {
          await GroupDailySummary.updateOne(
            { _id: summary._id },
            {
              $set: {
                isGroupDayComplete: true,
                completedAt: summary.completedAt || new Date(),
                eligibleCount: eligible.length,
                completedCount: rows.filter((r) => r.isDayComplete).length,
              },
            },
          );
        }
      } else if (!satisfied && summary.isGroupDayComplete) {
        stats.groupDaysReverted++;
        if (APPLY) {
          await GroupDailySummary.updateOne(
            { _id: summary._id },
            { $set: { isGroupDayComplete: false }, $unset: { completedAt: '' } },
          );
          await GroupActivity.deleteOne({
            groupId: group.groupId, type: 'group_day_completed', dateKey: summary.dateKey,
          });
        }
      }
    }
  }
  console.log(
    `group summaries: ${stats.groupDaysCompleted} to complete, ${stats.groupDaysReverted} to revert${APPLY ? ' — DONE' : ' (dry run)'}`,
  );
};

// ── Step 4: re-derive streak counters from the FIXED day records ──
const repairSoloStreaks = async () => {
  const solos = await SoloStreak.find({});
  for (const solo of solos) {
    const user = await User.findById(solo.userId).select('timezone').lean();
    const today = todayKeyInTz(user?.timezone || 'Asia/Karachi');
    const rows = await SoloDailyProgress.find({ userId: solo.userId, isDayComplete: true })
      .select('dateKey').lean();
    const days = new Set(rows.map((r) => r.dateKey));
    const { run, startDate } = currentRunFromDays(days, today);
    const best = Math.max(longestRunFromDays(days), run);
    const last = [...days].sort().pop() || null;
    const changed =
      solo.currentStreak !== run ||
      solo.bestStreak !== best ||
      solo.currentStreakStartDate !== startDate ||
      solo.lastCompletedDay !== last;
    if (!changed) continue;
    stats.soloStreaksFixed++;
    if (APPLY) {
      solo.currentStreak = run;
      solo.bestStreak = best;
      solo.currentStreakStartDate = startDate;
      solo.lastCompletedDay = last;
      solo.lastEvaluatedDay = today;
      await solo.save();
    }
  }
  console.log(`solo streaks: ${stats.soloStreaksFixed} to fix${APPLY ? ' — FIXED' : ' (dry run)'}`);
};

const repairGroupStreaks = async () => {
  const groups = await Group.find({});
  for (const group of groups) {
    const today = todayKeyInTz(group.timezone);
    const rows = await GroupDailySummary.find({ groupId: group.groupId, isGroupDayComplete: true })
      .select('dateKey').lean();
    const days = new Set(rows.map((r) => r.dateKey));
    const { run, startDate } = currentRunFromDays(days, today);
    const best = Math.max(longestRunFromDays(days), run);
    const changed =
      group.currentStreak !== run ||
      group.bestStreak !== best ||
      group.currentStreakStartDate !== startDate;
    if (!changed) continue;
    stats.groupsFixed++;
    if (APPLY) {
      group.currentStreak = run;
      group.bestStreak = best;
      group.currentStreakStartDate = startDate;
      group.lastEvaluatedDay = today;
      await group.save();
    }
  }
  console.log(`groups: ${stats.groupsFixed} to fix${APPLY ? ' — FIXED' : ' (dry run)'}`);
};

const main = async () => {
  console.log(`Mode: ${APPLY ? 'APPLY (writes)' : 'DRY RUN (use --apply to write)'}`);
  await connect();
  await repairProgressRows(SoloDailyProgress, 'solo');
  await repairProgressRows(GroupDailyProgress, 'group');
  await repairGroupSummaries();
  await repairSoloStreaks();
  await repairGroupStreaks();
  console.log('Summary:', stats);
  await mongoose.disconnect();
  console.log('Done.');
};

main().catch(async (e) => {
  console.error('Repair failed:', e);
  await mongoose.disconnect().catch(() => {});
  process.exit(1);
});
