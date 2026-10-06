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
const buyerChatController = require('./buyer/buyer-chat.controller');
const buyerChatService = require('./buyer/buyer-chat.service');
const currencyService = require('./services/currency.service');
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
    version: '1.1.0',
    features: ['worker-support', 'buyer-support'],
    timestamp: new Date().toISOString(),
  });
});

// ── Worker Support REST Routes ───────────────────────────────────────────────
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

// ── Buyer Support REST Routes (Extension Module) ─────────────────────────────
app.get('/api/support/buyer/conversations', (req, res) => buyerChatController.getConversations(req, res));
app.get('/api/support/buyer/conversations/:conversationId/messages', (req, res) => buyerChatController.getMessages(req, res));
app.get('/api/support/buyer/:buyerId', (req, res) => buyerChatController.getBuyerChat(req, res));
app.get('/api/support/buyer/:buyerId/unread', (req, res) => buyerChatController.getUnreadCount(req, res));
app.post('/api/support/buyer/token', (req, res) => buyerChatController.updateToken(req, res));
app.post('/api/support/buyer/messages/send', (req, res) => buyerChatController.sendMessage(req, res));
app.post('/api/support/buyer/conversations/:conversationId/read', (req, res) => buyerChatController.markRead(req, res));
app.post('/api/support/buyer/messages/delete', (req, res) => buyerChatController.deleteMessages(req, res));
app.delete('/api/support/buyer/conversations/:conversationId/messages', (req, res) => buyerChatController.deleteAllConversationMessages(req, res));
app.post('/api/support/buyer/conversations/delete', (req, res) => buyerChatController.deleteConversations(req, res));
app.post('/api/support/buyer/conversations/delete-bulk', (req, res) => buyerChatController.deleteConversations(req, res));

// ── Global Currency Settings (INR ⇄ USD) ──────────────────────────────────
app.get('/api/support/currency-settings', async (req, res) => {
  try {
    const settings = await currencyService.getSettings();
    res.json(settings);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/support/admin/currency-settings', async (req, res) => {
  try {
    const { defaultCurrency, usdExchangeRate, allowBuyerSwitch } = req.body;
    const result = await currencyService.updateSettings({
      defaultCurrency,
      usdExchangeRate,
      allowBuyerSwitch,
    });

    const io = req.app.get('io');
    if (io) {
      io.emit('currency_settings_updated', result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

const PORT = process.env.PORT || 3005;

async function startServer() {
  try {
    await initTables();
    await buyerChatService.initTables();
    server.listen(PORT, '0.0.0.0', () => {
      console.log(`=================================================`);
      console.log(`🚀 Support Chat Engine running on port ${PORT}`);
      console.log(`   Worker Support: /api/support/conversations`);
      console.log(`   Buyer Support:  /api/support/buyer/conversations`);
      console.log(`   Socket.IO:      ws://localhost:${PORT}`);
      console.log(`=================================================`);
    });
  } catch (err) {
    console.error('Failed to start support-chat-engine:', err);
    process.exit(1);
  }
}

startServer();
