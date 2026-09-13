import mongoose from 'mongoose';

let dbConnected = false;
let lastDbError = null;

const connectDB = async () => {
  if (!process.env.MONGODB_URI) {
    lastDbError = 'MONGODB_URI not configured';
    console.warn('MONGODB_URI not configured. Running without database connection.');
    return;
  }
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      serverSelectionTimeoutMS: 10000,
      socketTimeoutMS: 45000,
      // Connection pool sized for concurrent traffic (default is 5 — too
      // small once many users hit the API at the same time).
      maxPoolSize: 50,
      minPoolSize: 5,
    });
    dbConnected = true;
    lastDbError = null;
    console.log(`MongoDB Connected: ${conn.connection.host}`);
    mongoose.set('toObject', {});
    mongoose.set('toJSON', {});
  } catch (error) {
    lastDbError = `${error.name || 'Error'}: ${error.message}`;
    console.error(`MongoDB connection error: ${lastDbError}`);
    console.warn('Server will continue running without database. Set MONGODB_URI env var to fix.');
    // Retry in the background — Atlas/network blips or a whitelist change
    // should not require a manual redeploy to recover.
    setTimeout(() => { if (!dbConnected) connectDB(); }, 30000);
  }
};

export { dbConnected, lastDbError };
export default connectDB;
