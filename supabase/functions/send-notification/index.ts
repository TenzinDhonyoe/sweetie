import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const APNS_KEY_ID = Deno.env.get("APNS_KEY_ID")!;
const APNS_TEAM_ID = Deno.env.get("APNS_TEAM_ID")!;
const APNS_PRIVATE_KEY = Deno.env.get("APNS_PRIVATE_KEY")!;
const APNS_BUNDLE_ID = Deno.env.get("APNS_BUNDLE_ID") || "com.sweetie.app";

interface NotificationPayload {
  type: "tap" | "photo" | "note" | "question" | "partner_joined";
  sender_id: string;
  recipient_id: string;
  sender_name?: string;
  day_number?: number;
}

interface APNsPayload {
  aps: {
    alert: {
      title: string;
      body: string;
    };
    sound: string;
    badge?: number;
    "interruption-level"?: "passive" | "active" | "time-sensitive" | "critical";
    "relevance-score"?: number;
  };
  category: string;
}

serve(async (req) => {
  try {
    const payload: NotificationPayload = await req.json();
    const { type, sender_id, recipient_id, sender_name, day_number } = payload;

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { data: recipient } = await supabase
      .from("profiles")
      .select("push_token, display_name")
      .eq("id", recipient_id)
      .single();

    if (!recipient?.push_token) {
      return new Response(
        JSON.stringify({ error: "No push token for recipient" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    let senderDisplayName = sender_name;
    if (!senderDisplayName) {
      const { data: sender } = await supabase
        .from("profiles")
        .select("display_name")
        .eq("id", sender_id)
        .single();
      senderDisplayName = sender?.display_name || "Your partner";
    }

    const notification = buildNotification(type, senderDisplayName, day_number);

    await sendAPNs(recipient.push_token, notification);

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

function buildNotification(
  type: string,
  senderName: string,
  dayNumber?: number
): APNsPayload {
  switch (type) {
    case "tap":
      return {
        aps: {
          alert: {
            title: "💕",
            body: `${senderName} is thinking of you`,
          },
          sound: "default",
          "interruption-level": "time-sensitive",
          "relevance-score": 1.0,
        },
        category: "TAP",
      };

    case "photo":
      return {
        aps: {
          alert: {
            title: "📸 New Moment",
            body: `${senderName} sent you a moment`,
          },
          sound: "default",
          "interruption-level": "active",
        },
        category: "PHOTO",
      };

    case "note":
      return {
        aps: {
          alert: {
            title: "💌 Love Note",
            body: "You have a new love note",
          },
          sound: "default",
          "interruption-level": "active",
        },
        category: "NOTE",
      };

    case "question":
      return {
        aps: {
          alert: {
            title: "❓ Daily Question",
            body: `Day ${dayNumber || ""} question is ready!`,
          },
          sound: "default",
          "interruption-level": "active",
        },
        category: "QUESTION",
      };

    case "partner_joined":
      return {
        aps: {
          alert: {
            title: "🎉 You're connected!",
            body: `${senderName} joined your couple`,
          },
          sound: "default",
          "interruption-level": "time-sensitive",
          "relevance-score": 1.0,
        },
        category: "PARTNER_JOINED",
      };

    default:
      return {
        aps: {
          alert: {
            title: "Sweetie",
            body: "You have a new notification",
          },
          sound: "default",
        },
        category: "DEFAULT",
      };
  }
}

async function sendAPNs(deviceToken: string, payload: APNsPayload) {
  const jwt = await generateAPNsJWT();
  const isProduction = Deno.env.get("APNS_PRODUCTION") === "true";
  const apnsHost = isProduction
    ? "api.push.apple.com"
    : "api.sandbox.push.apple.com";

  const response = await fetch(
    `https://${apnsHost}/3/device/${deviceToken}`,
    {
      method: "POST",
      headers: {
        Authorization: `bearer ${jwt}`,
        "apns-topic": APNS_BUNDLE_ID,
        "apns-push-type": "alert",
        "apns-priority": "10",
        "apns-expiration": "0",
      },
      body: JSON.stringify(payload),
    }
  );

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`APNs error: ${response.status} - ${error}`);
  }
}

async function generateAPNsJWT(): Promise<string> {
  const header = {
    alg: "ES256",
    kid: APNS_KEY_ID,
  };

  const now = Math.floor(Date.now() / 1000);
  const claims = {
    iss: APNS_TEAM_ID,
    iat: now,
  };

  const encoder = new TextEncoder();

  const headerB64 = btoa(JSON.stringify(header))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
  const claimsB64 = btoa(JSON.stringify(claims))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");

  const unsignedToken = `${headerB64}.${claimsB64}`;

  const privateKeyPem = APNS_PRIVATE_KEY.replace(/\\n/g, "\n");
  const pemContents = privateKeyPem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");

  const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    cryptoKey,
    encoder.encode(unsignedToken)
  );

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");

  return `${unsignedToken}.${signatureB64}`;
}
