/**
 * Worker de prueba para validar el pipeline
 * Este worker responde con información básica
 */
export default {
  async fetch(request, env, ctx) {
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
}
