import { Router } from 'express';
import {
  getSolo,
  startSolo,
  getSoloHistory,
  completePrayer,
  getMyGroups,
  createGroup,
  discoverGroups,
  getGroupDashboard,
  getGroupActivity,
  getGroupHistory,
  leaveGroup,
  removeMember,
  renameGroup,
  rotateInviteCode,
  transferOwnership,
  archiveGroup,
  requestToJoin,
  getMyRequests,
  getGroupRequests,
  approveRequest,
  declineRequest,
  getInvitePreview,
  joinByInviteCode,
  getNotifications,
  markNotificationsSeen,
  registerDevice,
} from '../controllers/streakV2Controller.js';
import { generalLimiter } from '../middleware/rateLimiter.js';

const router = Router();

router.use(generalLimiter);

// ── Solo streak ──
router.get('/solo', getSolo);
router.post('/solo/start', startSolo);
router.post('/prayers/complete', completePrayer); // THE one canonical prayer tick
router.get('/solo/history', getSoloHistory);

// ── Groups: discovery & listing (static paths BEFORE :groupId) ──
router.get('/groups', getMyGroups);
router.post('/groups', createGroup);
router.get('/groups/discover', discoverGroups);
router.get('/requests/me', getMyRequests);

// ── Invite code / deep link ──
router.get('/invite/:code', getInvitePreview);
router.post('/invite/:code/join', joinByInviteCode);

// ── Join requests ──
router.post('/groups/:groupId/join-request', requestToJoin);
router.get('/groups/:groupId/requests', getGroupRequests);
router.post('/requests/:requestId/approve', approveRequest);
router.post('/requests/:requestId/decline', declineRequest);

// ── Group dashboard / activity / history ──
router.get('/groups/:groupId/dashboard', getGroupDashboard);
router.get('/groups/:groupId/activity', getGroupActivity);
router.get('/groups/:groupId/history', getGroupHistory);

// ── Group management ──
router.post('/groups/:groupId/leave', leaveGroup);
router.post('/groups/:groupId/rename', renameGroup);
router.post('/groups/:groupId/invite/rotate', rotateInviteCode);
router.post('/groups/:groupId/members/:userId/remove', removeMember);
router.post('/groups/:groupId/transfer', transferOwnership);
router.post('/groups/:groupId/archive', archiveGroup);

// ── Notifications (in-app feed; FCM-ready) & devices ──
router.get('/notifications', getNotifications);
router.post('/notifications/seen', markNotificationsSeen);
router.post('/devices', registerDevice);

export default router;
