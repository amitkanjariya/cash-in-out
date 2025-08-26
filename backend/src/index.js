import 'dotenv/config';
import mongoose from 'mongoose';
import os from 'os';
import app from './server.js';

const PORT = process.env.PORT || 3000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/cashinout';

async function start() {
	try {
		await mongoose.connect(MONGODB_URI, { autoIndex: true });
		console.log('MongoDB connected');

		app.listen(PORT, '0.0.0.0', () => {
			const ifaces = os.networkInterfaces();
			const addrs = [];
			Object.values(ifaces).forEach(list => {
				(list || []).forEach((iface) => {
					if (iface.family === 'IPv4' && !iface.internal) addrs.push(iface.address);
				});
			});
			console.log('Server running on:');
			console.log(`  - http://localhost:${PORT}`);
			addrs.forEach(ip => console.log(`  - http://${ip}:${PORT}`));
		});
	} catch (err) {
		console.error('Failed to start server:', err);
		process.exit(1);
	}
}

start();

