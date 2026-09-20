import AdhkarCategory from '../models/AdhkarCategory.js';

// Returns all adhkar categories (with per-item translations). The Flutter
// app treats the bundled Arabic dataset as source of truth and overlays
// these translations, so an empty collection degrades gracefully.
// toJSON() applies the schema transform (categoryId -> id, itemId -> id).
export const getAdhkar = async (req, res) => {
  const docs = await AdhkarCategory.find({}).sort({ categoryId: 1 });
  const categories = docs.map((d) => d.toJSON());
  return res.json({ success: true, data: categories, count: categories.length });
};
