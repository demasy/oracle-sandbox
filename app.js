const http = require('node:http');
let oracledb;
try { oracledb = require('oracledb'); } catch (err) { oracledb = null; console.warn('oracledb not available:', err.message); }

const PORT = Number(process.env.PORT || process.env.ENV_SERVER_PORT || 3000);
const HOST = process.env.HOST || '127.0.0.1';

const requiredHealthEnv = [
  'SANDBOX_DB_HOST',
  'SANDBOX_DB_PORT',
  'SANDBOX_DB_SERVICE',
  'SANDBOX_DB_USER',
  'SANDBOX_DB_PASS',
];

// Cached DB probe — refreshed every 30 seconds
const DB_PROBE_TTL_MS = 30_000;
let dbProbeCache = { status: 'unknown', checkedAt: 0, error: null };

async function probeDatabase() {
  const now = Date.now();
  if (now - dbProbeCache.checkedAt < DB_PROBE_TTL_MS) return dbProbeCache;

  if (!oracledb) {
    dbProbeCache = { status: 'unavailable', checkedAt: now, error: 'oracledb module not loaded' };
    return dbProbeCache;
  }

  const missingEnv = requiredHealthEnv.filter((n) => !process.env[n]);
  if (missingEnv.length > 0) {
    dbProbeCache = { status: 'unconfigured', checkedAt: now, error: `missing env: ${missingEnv.join(', ')}` };
    return dbProbeCache;
  }

  let conn;
  try {
    conn = await oracledb.getConnection({
      user: process.env.SANDBOX_DB_USER,
      password: process.env.SANDBOX_DB_PASS,
      connectString: `${process.env.SANDBOX_DB_HOST}:${process.env.SANDBOX_DB_PORT}/${process.env.SANDBOX_DB_SERVICE}`,
    });
    await conn.execute('SELECT 1 FROM DUAL');
    dbProbeCache = { status: 'pass', checkedAt: now, error: null };
  } catch (err) {
    dbProbeCache = { status: 'fail', checkedAt: now, error: err.message };
  } finally {
    if (conn) try { await conn.close(); } catch (closeErr) { console.warn('DB close error:', closeErr.message); }
  }
  return dbProbeCache;
}

// Kick off an initial probe at startup (non-blocking)
probeDatabase().catch(() => {});

function sendJson(res, statusCode, payload) {
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
  });
  res.end(`${body}\n`);
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

  if (url.pathname === '/health') {
    const missingEnv = requiredHealthEnv.filter((n) => !process.env[n]);
    const configOk = missingEnv.length === 0;

    const db = await probeDatabase();
    const healthy = configOk && db.status === 'pass';

    const payload = {
      status: healthy ? 'healthy' : 'degraded',
      service: 'oracle-sandbox-management',
      uptimeSeconds: Math.floor(process.uptime()),
      checks: {
        configuration: {
          status: configOk ? 'pass' : 'fail',
          missingEnv,
        },
        database: {
          status: db.status,
          ...(db.error ? { error: db.error } : {}),
        },
      },
    };
    sendJson(res, healthy ? 200 : 503, payload);
    return;
  }

  if (url.pathname === '/') {
    sendJson(res, 200, {
      service: 'oracle-sandbox-management',
      health: '/health',
    });
    return;
  }

  sendJson(res, 404, { error: 'not_found' });
});

server.listen(PORT, HOST, () => {
  console.log(`Oracle Sandbox management server listening on ${HOST}:${PORT}`);
});
