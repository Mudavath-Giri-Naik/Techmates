// @ts-nocheck
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { create } from "https://deno.land/x/djwt@v2.9.1/mod.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID")!;
const FIREBASE_CLIENT_EMAIL = Deno.env.get("FIREBASE_CLIENT_EMAIL")!;
const FIREBASE_PRIVATE_KEY = Deno.env.get("FIREBASE_PRIVATE_KEY")!.replace(/\\n/g, "\n");

serve(async (req) => {
    try {
        const { token, title, body, broadcast } = await req.json();

        const jwt = await getFirebaseAccessToken();

        let tokens: string[] = [];

        if (broadcast) {
            // Initialize Supabase Client
            const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
            const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
            const supabase = createClient(supabaseUrl, supabaseKey);

            // Fetch all tokens from profiles
            const { data: profiles, error } = await supabase
                .from("profiles")
                .select("fcm_token")
                .not("fcm_token", "is", null);

            if (error) throw error;

            tokens = profiles.map((p) => p.fcm_token).filter((t) => t);
        } else if (token) {
            tokens = [token];
        } else {
            return new Response(JSON.stringify({ error: "No token provided" }), { status: 400 });
        }

        // Send notifications
        const promises = tokens.map((fcmToken) =>
            fetch(
                `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
                {
                    method: "POST",
                    headers: {
                        "Authorization": `Bearer ${jwt}`,
                        "Content-Type": "application/json",
                    },
                    body: JSON.stringify({
                        message: {
                            token: fcmToken,
                            notification: {
                                title: title,
                                body: body,
                            },
                        },
                    }),
                }
            ).then((res) => res.json())
        );

        const results = await Promise.all(promises);

        return new Response(JSON.stringify({ success: true, results }), {
            headers: { "Content-Type": "application/json" },
        });
    } catch (err) {
        return new Response(JSON.stringify({ error: err.message }), {
            status: 500,
            headers: { "Content-Type": "application/json" },
        });
    }
});

async function getFirebaseAccessToken() {
    const iat = Math.floor(Date.now() / 1000);
    const exp = iat + 3600; // 1 hour

    const payload = {
        iss: FIREBASE_CLIENT_EMAIL,
        sub: FIREBASE_CLIENT_EMAIL,
        aud: "https://oauth2.googleapis.com/token",
        iat,
        exp,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
    };

    const key = await importKey(FIREBASE_PRIVATE_KEY);

    // Sign JWT
    const jwt = await create({ alg: "RS256", typ: "JWT" }, payload, key);

    // Exchange JWT for Access Token
    const tokensRes = await fetch("https://oauth2.googleapis.com/token", {
        method: "POST",
        headers: {
            "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
            grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
            assertion: jwt,
        }),
    });

    const tokens = await tokensRes.json();
    if (!tokens.access_token) {
        throw new Error(`Failed to get access token: ${JSON.stringify(tokens)}`);
    }

    return tokens.access_token;
}

async function importKey(pem: string): Promise<CryptoKey> {
    // Clean up PEM header/footer
    const pemHeader = "-----BEGIN PRIVATE KEY-----";
    const pemFooter = "-----END PRIVATE KEY-----";

    let pemContents = pem;
    if (pem.includes(pemHeader)) {
        pemContents = pem.substring(
            pem.indexOf(pemHeader) + pemHeader.length,
            pem.indexOf(pemFooter)
        );
    }

    // Remove newlines
    const binaryDerString = atob(pemContents.replace(/\s/g, ""));

    // Convert to ArrayBuffer
    const binaryDer = new Uint8Array(binaryDerString.length);
    for (let i = 0; i < binaryDerString.length; i++) {
        binaryDer[i] = binaryDerString.charCodeAt(i);
    }

    return await crypto.subtle.importKey(
        "pkcs8",
        binaryDer.buffer,
        {
            name: "RSASSA-PKCS1-v1_5",
            hash: "SHA-256",
        },
        true,
        ["sign"]
    );
}
