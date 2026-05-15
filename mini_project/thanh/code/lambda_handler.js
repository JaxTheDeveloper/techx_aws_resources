'use strict';

const http = require('http');
const app = require('./app');

// create a real http server wrapping the express app. this instance persists
// across warm lambda invocations, so we only pay the listen() cost once.

// inspired from the simpleton pattern when defining database conns
// on serverless applications form the digital course.
const server = http.createServer(app);

// lazily start listening on an ephemeral port (os picks it, avoids conflicts).
// subsequent calls return the same promise, so the server is only bound once.
let serverReady;
function getServer() {
  if (!serverReady) {
    serverReady = new Promise((resolve, reject) => {
      server.listen(0, '127.0.0.1', () => resolve(server));
      server.once('error', reject);
    });
  }
  return serverReady;
}

// actual lambda handler
exports.handler = async (event) => {
  const srv = await getServer();
  const { port } = srv.address();

  const qs = event.rawQueryString ? `?${event.rawQueryString}` : '';
  const path = (event.rawPath || '/') + qs;

  // in case apigw encodes it in base64 for the body, we handle both cases
  let bodyBuffer = null;
  if (event.body) {
    bodyBuffer = event.isBase64Encoded
      ? Buffer.from(event.body, 'base64')
      : Buffer.from(event.body, 'utf8');
  }

  const method = event.requestContext.http.method;
  const incomingHeaders = Object.assign({}, event.headers || {});

  // content-length must reflect the decoded byte length, not the original string length
  if (bodyBuffer) {
    incomingHeaders['content-length'] = String(bodyBuffer.byteLength);
  }

  return new Promise((resolve, reject) => {
    const proxyReq = http.request(
      { hostname: '127.0.0.1', port, path, method, headers: incomingHeaders },
      (proxyRes) => {
        const chunks = [];
        proxyRes.on('data', (chunk) => chunks.push(chunk));
        proxyRes.on('end', () => {
          const rawBody = Buffer.concat(chunks);

          // text-based content types can be returned as utf8 strings;
          // everything else (images, binary) gets base64-encoded for api gateway
          const contentType = (proxyRes.headers['content-type'] || '').toLowerCase();
          const isText = ['json', 'text', 'xml', 'javascript'].some((t) => contentType.includes(t));
          const isBase64Encoded = !isText;

          resolve({
            statusCode: proxyRes.statusCode,
            headers: proxyRes.headers,
            body: isBase64Encoded ? rawBody.toString('base64') : rawBody.toString('utf8'),
            isBase64Encoded,
          });
        });
        proxyRes.on('error', reject);
      }
    );

    proxyReq.on('error', reject);
    if (bodyBuffer) proxyReq.write(bodyBuffer);
    proxyReq.end();
  });
};
