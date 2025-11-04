/**
 * Worker de prueba para validar el pipeline
 * Este worker responde con información básica
 * Compatible con Cloudflare Workers (no ES6 modules)
 */
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  const url = new URL(request.url);

  return new Response(JSON.stringify({
    message: 'Worker de prueba - Infra Elite',
    path: url.pathname,
    method: request.method,
    timestamp: new Date().toISOString(),
    worker: 'test-worker'
  }), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}
