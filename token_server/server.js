require('dotenv').config();
const express = require('express');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const fetch = require('node-fetch');

const app = express();
app.use(express.json());

const HMS_APP_ACCESS_KEY = process.env.HMS_APP_ACCESS_KEY;
const HMS_APP_SECRET = process.env.HMS_APP_SECRET;
const HMS_TEMPLATE_ID = process.env.HMS_TEMPLATE_ID;

if (!HMS_APP_ACCESS_KEY || !HMS_APP_SECRET) {
  console.error('ERROR: HMS_APP_ACCESS_KEY and HMS_APP_SECRET must be set in .env');
  process.exit(1);
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function generateManagementToken() {
  const payload = {
    access_key: HMS_APP_ACCESS_KEY,
    type: 'management',
    version: 2,
    jti: uuidv4(),
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 86400,
    nbf: Math.floor(Date.now() / 1000),
  };
  return jwt.sign(payload, HMS_APP_SECRET, { algorithm: 'HS256' });
}

function generateAppToken(userId, role, roomId) {
  const payload = {
    access_key: HMS_APP_ACCESS_KEY,
    type: 'app',
    version: 2,
    role: role,
    room_id: roomId,
    user_id: userId,
    jti: uuidv4(),
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 86400,
    nbf: Math.floor(Date.now() / 1000),
  };
  return jwt.sign(payload, HMS_APP_SECRET, { algorithm: 'HS256' });
}

// ─── Routes ───────────────────────────────────────────────────────────────────

// Health check
app.get('/health', (req, res) => res.json({ status: 'ok' }));

// GET /token?userId=DK&role=member&roomId=xxx
app.get('/token', (req, res) => {
  const { userId, role, roomId } = req.query;
  if (!userId || !role || !roomId) {
    return res.status(400).json({
      error: 'Missing required query params: userId, role, roomId',
    });
  }
  if (!['trainer', 'member', 'host', 'guest'].includes(role)) {
    return res.status(400).json({ error: 'role must be host, guest, trainer, or member' });
  }
  const token = generateAppToken(userId, role, roomId);
  console.log(`[TOKEN] Generated for userId=${userId} role=${role} roomId=${roomId}`);
  res.json({ token });
});

// POST /room  body: { name: string }
app.post('/room', async (req, res) => {
  const { name, templateId } = req.body;
  if (!name) return res.status(400).json({ error: 'name is required' });

  try {
    const mgmtToken = generateManagementToken();
    const response = await fetch('https://api.100ms.live/v2/rooms', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${mgmtToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        name,
        description: 'WTF Gym session',
        // body templateId takes precedence over .env so the correct
        // host/guest template is always used
        template_id: templateId || HMS_TEMPLATE_ID || undefined,
      }),
    });

    const data = await response.json();
    if (!response.ok) {
      console.error('[ROOM] 100ms API error:', data);
      // Fallback: return a synthetic roomId so app can continue
      return res.json({ id: `local_${name}`, name, fallback: true });
    }
    console.log(`[ROOM] Created: ${data.id}`);
    res.json(data);
  } catch (err) {
    console.error('[ROOM] Error:', err.message);
    res.json({ id: `local_${name}`, name, fallback: true });
  }
});

// ─── Start ────────────────────────────────────────────────────────────────────

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`WTF Gym token server running on http://localhost:${PORT}`);
  console.log(`  GET  /token?userId=<id>&role=<trainer|member>&roomId=<id>`);
  console.log(`  POST /room  { "name": "<name>" }`);
});
