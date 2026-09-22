const http = require('http');
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { Server } = require('socket.io');
require('dotenv').config();

const { initTables } = require('./config/db');
const chatController = require('./controllers/chat.controller');
const { setupSocketIO } = require('./sockets/chat.socket');

const app = express();
const server = http.createServer(app);

// CORS configuration
app.use(cors({ origin: '*' }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}
app.use('/uploads', express.static(uploadsDir));

// Multer storage for media uploads (images and voice audio)
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadsDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || (file.mimetype.includes('audio') ? '.m4a' : '.jpg');
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, `${uniqueSuffix}${ext}`);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 25 * 1024 * 1024 }, // 25MB
});

// Setup Socket.IO
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
  pingTimeout: 30000,
  pingInterval: 10000,
});
setupSocketIO(io);
app.set('io', io);

// ── Health Check ─────────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    service: 'support-chat-engine',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// ── REST Routes ──────────────────────────────────────────────────────────────
app.get('/api/support/conversations', (req, res) => chatController.getConversations(req, res));
app.get('/api/support/conversations/:conversationId/messages', (req, res) => chatController.getMessages(req, res));
app.get('/api/support/worker/:workerId', (req, res) => chatController.getWorkerChat(req, res));
app.post('/api/support/messages/send', (req, res) => chatController.sendMessage(req, res));
app.post('/api/support/messages/bulk', (req, res) => chatController.sendBulkMessage(req, res));
app.post('/api/support/conversations/:conversationId/read', (req, res) => chatController.markRead(req, res));
app.get('/api/support/workers/filterable', (req, res) => chatController.getFilterableWorkers(req, res));
app.post('/api/support/upload', upload.single('file'), (req, res) => chatController.uploadMedia(req, res));
app.post('/api/support/messages/delete', (req, res) => chatController.deleteMessages(req, res));
app.delete('/api/support/conversations/:conversationId/messages', (req, res) => chatController.deleteAllConversationMessages(req, res));
app.post('/api/support/conversations/delete-bulk', (req, res) => chatController.deleteConversationsBulk(req, res));
app.post('/api/support/conversations/delete-all', (req, res) => chatController.deleteAllWorkersChats(req, res));

const PORT = process.env.PORT || 3005;

async function startServer() {
  try {
    await initTables();
    server.listen(PORT, '0.0.0.0', () => {
      console.log(`=================================================`);
      console.log(`🚀 Support Chat Engine running on port ${PORT}`);
      console.log(`   Health check: http://localhost:${PORT}/health`);
      console.log(`   Socket.IO path: ws://localhost:${PORT}`);
      console.log(`=================================================`);
    });
  } catch (err) {
    console.error('Failed to start support-chat-engine:', err);
    process.exit(1);
  }
}

startServer();
