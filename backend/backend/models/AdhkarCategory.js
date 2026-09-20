import mongoose from 'mongoose';

// Mirrors the bundled Hisnul Muslim dataset (lib/data/azkar_data.dart in the
// Flutter app) with a multi-language translations overlay. Arabic text stays
// the source of truth; the app merges server translations on top of the
// bundled data so it keeps working offline.
//
// NOTE: the persisted item key is `itemId` because `id` is a reserved
// virtual in Mongoose. The toJSON transform maps everything back to the
// exact shape the Flutter app expects (id / category / items[].id).
const zikrItemSchema = new mongoose.Schema(
  {
    itemId: { type: Number, required: true },
    text: { type: String, required: true },
    count: { type: Number, default: 1 },
    audio: { type: String, default: '' },
    translations: {
      ur: { type: String, default: '' },
      en: { type: String, default: '' },
      hi: { type: String, default: '' },
      id: { type: String, default: '' },
    },
  },
  { _id: false }
);

const adhkarCategorySchema = new mongoose.Schema(
  {
    categoryId: { type: Number, required: true, unique: true },
    category: { type: String, required: true },
    audio: { type: String, default: '' },
    translations: {
      ur: { type: String, default: '' },
      en: { type: String, default: '' },
      hi: { type: String, default: '' },
      id: { type: String, default: '' },
    },
    items: { type: [zikrItemSchema], default: [] },
  },
  {
    timestamps: true,
    toJSON: {
      transform: (_doc, ret) => {
        ret.id = ret.categoryId;
        delete ret.categoryId;
        delete ret.__v;
        if (Array.isArray(ret.items)) {
          ret.items = ret.items.map(({ itemId, ...rest }) => ({
            id: itemId,
            ...rest,
          }));
        }
        return ret;
      },
    },
  }
);

export default mongoose.model('AdhkarCategory', adhkarCategorySchema);
