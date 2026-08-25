// Delivers queued notification_outbox rows through FCM HTTP v1.
// Secrets (supabase secrets set): FCM_SERVICE_ACCOUNT = the Firebase service-account JSON.
// Schedule: pg_cron -> net.http_post to this function every 5 minutes (see supabase/README.md).
import { createClient } from "npm:@supabase/supabase-js@2";

const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

function b64url(data: Uint8Array | string): string {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : data;
  return btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function accessToken(sa: { client_email: string; private_key: string; token_uri: string }): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = b64url(JSON.stringify({
    iss: sa.client_email, scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: sa.token_uri, iat: now, exp: now + 3600,
  }));
  const pem = sa.private_key.replace(/-----[A-Z ]+-----/g, "").replace(/\s+/g, "");
  const key = await crypto.subtle.importKey("pkcs8", Uint8Array.from(atob(pem), (c) => c.charCodeAt(0)),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
  const sig = new Uint8Array(await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(`${header}.${claims}`)));
  const jwt = `${header}.${claims}.${b64url(sig)}`;
  const res = await fetch(sa.token_uri, {
    method: "POST", headers: { "content-type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });
  const json = await res.json();
  if (!json.access_token) throw new Error(`token: ${JSON.stringify(json)}`);
  return json.access_token;
}

Deno.serve(async () => {
  const sa = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT") ?? "{}");
  if (!sa.client_email) return new Response("FCM_SERVICE_ACCOUNT not set", { status: 500 });
  const { data: rows, error } = await supabase.from("notification_outbox").select("id,user_id,title,body,data").is("sent_at", null).limit(200);
  if (error) return new Response(error.message, { status: 500 });
  if (!rows?.length) return new Response("nothing to send");
  const token = await accessToken(sa);
  let sent = 0;
  for (const row of rows) {
    const { data: devices } = await supabase.from("device_tokens").select("token").eq("user_id", row.user_id);
    let err: string | null = null;
    for (const d of devices ?? []) {
      const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
        method: "POST",
        headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
        body: JSON.stringify({ message: {
          token: d.token,
          notification: { title: row.title, body: row.body },
          data: Object.fromEntries(Object.entries(row.data ?? {}).map(([k, v]) => [k, String(v)])),
          android: { priority: "high", notification: { channel_id: "photorank_reminders" } },
        } }),
      });
      if (!res.ok) {
        err = `${res.status} ${await res.text()}`;
        if (res.status === 404 || res.status === 410) await supabase.from("device_tokens").delete().eq("token", d.token);
      }
    }
    await supabase.from("notification_outbox").update({ sent_at: new Date().toISOString(), error: err }).eq("id", row.id);
    sent++;
  }
  return new Response(`sent ${sent}`);
});
