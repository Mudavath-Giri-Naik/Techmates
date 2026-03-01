const SUPABASE_URL = "https://hmcxfkirqqifahhbipdt.supabase.co";
const SUPABASE_WSS = "wss://hmcxfkirqqifahhbipdt.supabase.co";

export default {
    async fetch(request, env) {
        const url = new URL(request.url);

        // Handle CORS preflight
        if (request.method === "OPTIONS") {
            return new Response(null, {
                status: 204,
                headers: corsHeaders(),
            });
        }

        // Handle WebSocket upgrade
        const upgradeHeader = request.headers.get("Upgrade");
        if (upgradeHeader && upgradeHeader.toLowerCase() === "websocket") {
            const targetUrl = SUPABASE_WSS + url.pathname + url.search;
            return fetch(targetUrl, request);
        }

        // Build the target URL
        const targetUrl = SUPABASE_URL + url.pathname + url.search;

        const newRequest = new Request(targetUrl, {
            method: request.method,
            headers: request.headers,
            body: request.method !== "GET" && request.method !== "HEAD"
                ? request.body
                : null,
            redirect: "follow",
        });

        try {
            const response = await fetch(newRequest);

            const newHeaders = new Headers(response.headers);
            addCorsHeaders(newHeaders);

            return new Response(response.body, {
                status: response.status,
                statusText: response.statusText,
                headers: newHeaders,
            });
        } catch (error) {
            return new Response(
                JSON.stringify({ error: "Proxy error", details: error.message }),
                {
                    status: 502,
                    headers: {
                        "Content-Type": "application/json",
                        ...corsHeaders(),
                    },
                }
            );
        }
    },
};

function corsHeaders() {
    return {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-api-version",
        "Access-Control-Max-Age": "86400",
    };
}

function addCorsHeaders(headers) {
    headers.set("Access-Control-Allow-Origin", "*");
    headers.set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS");
    headers.set("Access-Control-Allow-Headers", "authorization, x-client-info, apikey, content-type, x-supabase-api-version");
}
