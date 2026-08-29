import { Router } from 'express';
import {
  getAdminStats,
  createEvent, updateEvent, deleteEvent,
  createDua, updateDua, deleteDua,
  createManualNotification,
} from '../controllers/adminController.js';
import seedEvents from '../scripts/seedEvents.js';
import seedDuas from '../scripts/seedDuas.js';
import seedWazifas from '../scripts/seedWazifas.js';

const router = Router();

router.get('/stats', getAdminStats);

router.post('/seed', async (req, res) => {
  try {
    await seedEvents();
    await seedDuas();
    await seedWazifas();
    res.json({ success: true, message: 'All data seeded successfully!' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post('/events', createEvent);
router.put('/events/:id', updateEvent);
router.delete('/events/:id', deleteEvent);

router.post('/duas', createDua);
router.put('/duas/:id', updateDua);
router.delete('/duas/:id', deleteDua);

router.post('/notifications', createManualNotification);

export default router;
