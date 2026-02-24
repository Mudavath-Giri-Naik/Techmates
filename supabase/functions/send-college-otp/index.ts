// supabase/functions/send-college-otp/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const { user_id, college_email } = await req.json()

        // Validate inputs
        if (!user_id || !college_email) {
            return new Response(
                JSON.stringify({ success: false, error: 'Missing user_id or college_email' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        const supabase = createClient(
            Deno.env.get('SUPABASE_URL')!,
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
        )

        const today = new Date().toISOString().split('T')[0] // YYYY-MM-DD

        // ── CHECK DAILY LIMIT ──────────────────────────
        const { data: counter } = await supabase
            .from('daily_email_counter')
            .select('count')
            .eq('date', today)
            .maybeSingle()

        const currentCount = counter?.count ?? 0

        if (currentCount >= 90) {
            return new Response(
                JSON.stringify({
                    success: false,
                    limit_reached: true,
                    message: 'Daily limit reached'
                }),
                {
                    status: 429,
                    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
                }
            )
        }

        // ── INCREMENT COUNTER ──────────────────────────
        const { error: counterError } = await supabase
            .from('daily_email_counter')
            .upsert(
                {
                    date: today,
                    count: currentCount + 1,
                    updated_at: new Date().toISOString()
                },
                { onConflict: 'date' }
            )

        if (counterError) {
            console.error('Counter upsert error:', counterError)
        }

        // ── GENERATE OTP ───────────────────────────────
        const otp_code = Math.floor(100000 + Math.random() * 900000).toString()
        const expires_at = new Date(Date.now() + 10 * 60 * 1000).toISOString()

        // Delete old unused OTPs for this user
        await supabase
            .from('college_email_otps')
            .delete()
            .eq('user_id', user_id)
            .eq('is_used', false)

        // Store new OTP
        const { error: insertError } = await supabase
            .from('college_email_otps')
            .insert({ user_id, college_email, otp_code, expires_at })

        if (insertError) {
            console.error('OTP insert error:', insertError)
            return new Response(
                JSON.stringify({ success: false, error: 'Failed to store OTP' }),
                { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // ── SEND EMAIL via Resend ──────────────────────
        // IMPORTANT: Replace the 'from' address with your verified domain in Resend.
        // If you don't have a verified domain yet, use: 'Techmates <onboarding@resend.dev>'
        // (Resend provides this sandbox sender for testing)
        const resendApiKey = Deno.env.get('RESEND_API_KEY')
        if (!resendApiKey) {
            console.error('RESEND_API_KEY is not set in edge function secrets')
            return new Response(
                JSON.stringify({ success: false, error: 'Email service not configured' }),
                { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        const emailResponse = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${resendApiKey}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                from: 'Techmates <noreply@mail.girinaik.in>',
                to: college_email,
                subject: `${otp_code} is your Techmates verification code`,
                html: `
          <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; max-width: 420px; margin: 0 auto; padding: 32px;">
            <h2 style="color: #2563EB; margin-bottom: 8px;">Verify your college email</h2>
            <p style="color: #6B7280; font-size: 14px; margin-bottom: 24px;">Enter this code in the Techmates app to complete verification.</p>
            <div style="background: #F3F4F6; border-radius: 12px; padding: 24px; text-align: center; margin-bottom: 24px;">
              <span style="font-size: 42px; font-weight: 800; letter-spacing: 8px; color: #111827;">${otp_code}</span>
            </div>
            <p style="color: #9CA3AF; font-size: 12px;">This code expires in 10 minutes. Do not share it with anyone.</p>
          </div>
        `
            })
        })

        if (!emailResponse.ok) {
            const errorBody = await emailResponse.text()
            console.error('Resend API error:', emailResponse.status, errorBody)

            // Roll back the counter
            await supabase
                .from('daily_email_counter')
                .update({ count: currentCount })
                .eq('date', today)

            return new Response(
                JSON.stringify({
                    success: false,
                    error: 'Email sending failed',
                    resend_status: emailResponse.status,
                    resend_error: errorBody
                }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        return new Response(
            JSON.stringify({ success: true }),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        console.error('Unhandled error:', error.message)
        return new Response(
            JSON.stringify({ success: false, error: error.message }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
