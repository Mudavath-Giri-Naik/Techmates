// @ts-nocheck
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
    try {
        const payload = await req.json();
        const record = payload.record;

        if (!record) {
            return new Response(JSON.stringify({ error: "No record provided" }), {
                status: 400,
                headers: { "Content-Type": "application/json" },
            });
        }

        const typeEmojis: Record<string, string> = {
            internship: "🚀",
            hackathon: "🏆",
            event: "📅",
            meetup: "🤝",
            competition: "🎯",
        };

        const emoji = typeEmojis[record.type] || "📢";
        const typeCapitalized = record.type.charAt(0).toUpperCase() + record.type.slice(1);

        const title = `${emoji} New ${typeCapitalized} Opportunity`;

        // Format date if needed, but keeping it simple as requested
        const body = `${record.title}\n${record.organization} • ${record.location}\nDeadline: ${record.deadline}\nTap to view details`;

        // Call send-notification function
        const res = await fetch(
            `${SUPABASE_URL}/functions/v1/send-notification`,
            {
                method: "POST",
                headers: {
                    "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    broadcast: true,
                    title: title,
                    body: body,
                }),
            }
        );

        const data = await res.json();

        return new Response(JSON.stringify(data), {
            headers: { "Content-Type": "application/json" },
        });

    } catch (err) {
        return new Response(JSON.stringify({ error: err.message }), {
            status: 500,
            headers: { "Content-Type": "application/json" },
        });
    }
});
