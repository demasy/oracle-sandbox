const http = require('http');

const PORT = Number(process.env.PORT || process.env.ENV_SERVER_PORT || 3000);
const HOST = process.env.HOST || '127.0.0.1';

const requiredHealthEnv = [
  'SANDBOX_DB_HOST',
  'SANDBOX_DB_PORT',
  'SANDBOX_DB_SERVICE',
  'SANDBOX_DB_USER',
  'SANDBOX_DB_PASS',
];

function sendJson(res, statusCode, payload) {
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
  });
  res.end(`${body}\n`);
}

function healthPayload() {
  const missingEnv = requiredHealthEnv.filter((name) => !process.env[name]);
  const healthy = missingEnv.length === 0;

  return {
    status: healthy ? 'healthy' : 'degraded',
    service: 'oracle-sandbox-management',
    uptimeSeconds: Math.floor(process.uptime()),
    checks: {
      configuration: {
        status: healthy ? 'pass' : 'fail',
        missingEnv,
      },
    },
  };
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

  if (url.pathname === '/health') {
    const payload = healthPayload();
    sendJson(res, payload.status === 'healthy' ? 200 : 503, payload);
    return;
  }

  if (url.pathname === '/') {
    sendJson(res, 200, {
      service: 'oracle-sandbox-management',
      health: '/health',
    });
    return;
  }

  sendJson(res, 404, {
    error: 'not_found',
  });
});

server.listen(PORT, HOST, () => {
  console.log(`Oracle Sandbox management server listening on ${HOST}:${PORT}`);
});
