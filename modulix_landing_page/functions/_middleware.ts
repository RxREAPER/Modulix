// Cloudflare Pages Functions Middleware — Modulix Edge Reverse Proxy to Supabase
// Routes all /auth/*, /rest/*, /storage/*, /realtime/*, and /functions/* requests to Supabase backend

interface EventContext {
  request: Request;
  next: () => Promise<Response>;
}

const SUPABASE_TARGET_ORIGIN = "https://vbvmzjhzznxgofyzxnql.supabase.co";

export async function onRequest(context: EventContext): Promise<Response> {
  const url = new URL(context.request.url);
  const pathname = url.pathname;

  const isSupabaseRoute =
    pathname.startsWith("/auth/") ||
    pathname.startsWith("/rest/") ||
    pathname.startsWith("/storage/") ||
    pathname.startsWith("/realtime/") ||
    pathname.startsWith("/functions/");

  if (!isSupabaseRoute) {
    // Pass through to static assets / SPA frontend
    return context.next();
  }

  // Handle CORS preflight OPTIONS requests immediately at the edge
  if (context.request.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        "Access-Control-Max-Age": "86400",
      },
    });
  }

  // Rewrite target destination to Supabase
  const targetUrl = new URL(pathname + url.search, SUPABASE_TARGET_ORIGIN);

  // Clone headers and rewrite Host header for Supabase SNI & routing
  const headers = new Headers(context.request.headers);
  headers.set("Host", "vbvmzjhzznxgofyzxnql.supabase.co");

  // Support WebSocket upgrading for Supabase Realtime
  if (context.request.headers.get("Upgrade")?.toLowerCase() === "websocket") {
    return fetch(targetUrl.toString(), {
      headers: headers,
    });
  }

  const isBodyAllowed = !["GET", "HEAD"].includes(context.request.method);

  const proxyRequest = new Request(targetUrl.toString(), {
    method: context.request.method,
    headers: headers,
    body: isBodyAllowed ? context.request.body : undefined,
    redirect: "follow",
  });

  try {
    const response = await fetch(proxyRequest);

    // Add CORS headers to the proxied response
    const responseHeaders = new Headers(response.headers);
    responseHeaders.set("Access-Control-Allow-Origin", "*");
    responseHeaders.set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS");
    responseHeaders.set("Access-Control-Allow-Headers", "authorization, x-client-info, apikey, content-type");

    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: responseHeaders,
    });
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: "Modulix Cloud Edge Proxy Error",
        message: error instanceof Error ? error.message : "Failed to fetch from backend",
      }),
      {
        status: 502,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  }
}
