import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import connectDB from '../config/db.js';
import seedEvents from './seedEvents.js';
import seedDuas from './seedDuas.js';
import seedWazifas from './seedWazifas.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: join(__dirname, '..', '..', '.env') });

const seed = async () => {
  try {
    console.log('Connecting to MongoDB...');
    await connectDB();

    console.log('\n--- Seeding Events ---');
    await seedEvents();

    console.log('\n--- Seeding Duas ---');
    await seedDuas();

    console.log('\n--- Seeding Wazifas ---');
    await seedWazifas();

    console.log('\n--- All data seeded successfully! ---');
    process.exit(0);
  } catch (error) {
    console.error('\nSeeding failed:', error.message);
    process.exit(1);
  }
};

seed();
