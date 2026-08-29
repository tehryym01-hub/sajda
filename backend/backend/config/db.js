import mongoose from 'mongoose';

let dbConnected = false;

const connectDB = async () => {
  if (!process.env.MONGODB_URI) {
    console.warn('MONGODB_URI not configured. Running without database connection.');
    return;
  }
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      serverSelectionTimeoutMS: 10000,
      socketTimeoutMS: 45000,
    });
    dbConnected = true;
    console.log(`MongoDB Connected: ${conn.connection.host}`);
    mongoose.set('toObject', {});
    mongoose.set('toJSON', {});
  } catch (error) {
    console.error(`MongoDB connection error: ${error.message}`);
    console.warn('Server will continue running without database. Set MONGODB_URI env var to fix.');
  }
};

export { dbConnected };
export default connectDB;
