import Event from '../models/Event.js';
import Dua from '../models/Dua.js';
import ManualNotification from '../models/ManualNotification.js';
import { sendPushManual } from '../services/push.js';

export const getAdminStats = async (req, res, next) => {
  try {
    const totalEvents = await Event.countDocuments();
    const totalDuas = await Dua.countDocuments();

    res.json({ success: true, data: { totalEvents, totalDuas } });
  } catch (error) {
    next(error);
  }
};

// Events CRUD
export const createEvent = async (req, res, next) => {
  try {
    const event = await Event.create(req.body);
    res.status(201).json({ success: true, data: event });
  } catch (error) {
    next(error);
  }
};

export const updateEvent = async (req, res, next) => {
  try {
    const event = await Event.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!event) { res.status(404); throw new Error('Event not found'); }
    res.json({ success: true, data: event });
  } catch (error) {
    next(error);
  }
};

export const deleteEvent = async (req, res, next) => {
  try {
    const event = await Event.findByIdAndDelete(req.params.id);
    if (!event) { res.status(404); throw new Error('Event not found'); }
    res.json({ success: true, message: 'Event deleted' });
  } catch (error) {
    next(error);
  }
};

// Duas CRUD
export const createDua = async (req, res, next) => {
  try {
    const dua = await Dua.create(req.body);
    res.status(201).json({ success: true, data: dua });
  } catch (error) {
    next(error);
  }
};

export const updateDua = async (req, res, next) => {
  try {
    const dua = await Dua.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!dua) { res.status(404); throw new Error('Dua not found'); }
    res.json({ success: true, data: dua });
  } catch (error) {
    next(error);
  }
};

export const deleteDua = async (req, res, next) => {
  try {
    const dua = await Dua.findByIdAndDelete(req.params.id);
    if (!dua) { res.status(404); throw new Error('Dua not found'); }
    res.json({ success: true, message: 'Dua deleted' });
  } catch (error) {
    next(error);
  }
};

// Manual Notifications
export const createManualNotification = async (req, res, next) => {
  try {
    const notification = await ManualNotification.create(req.body);
    // Also send as push to all subscribers
    sendPushManual(req.body.title, req.body.body || '').catch(err => console.error('Push send error:', err.message));
    res.status(201).json({ success: true, data: notification });
  } catch (error) {
    next(error);
  }
};

export const getManualNotifications = async (req, res, next) => {
  try {
    const since = req.query.since || new Date(0).toISOString();
    const notifications = await ManualNotification.find({
      active: true,
      createdAt: { $gt: new Date(since) },
    }).sort({ createdAt: -1 }).lean();
    res.json({ success: true, data: notifications });
  } catch (error) {
    next(error);
  }
};


