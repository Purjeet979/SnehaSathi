import axios from "axios";

const GRAPH_API = "https://graph.facebook.com/v21.0";

/**
 * WhatsApp Cloud API se message bhejne ka function.
 * 
 * Pehle template try karta hai — agar template approved nahi hai
 * toh plain text message bhejta hai (24-hour window mein kaam karega).
 */
export async function sendWhatsApp(phoneNumber, summary, memberName, elderName) {
  const formattedNumber = phoneNumber.replace(/\D/g, "");
  const phoneId = process.env.PHONE_ID;
  const token = process.env.WHATSAPP_TOKEN;

  if (!phoneId || !token) {
    throw new Error("❌ PHONE_ID ya WHATSAPP_TOKEN environment variable missing hai!");
  }

  const url = `${GRAPH_API}/${phoneId}/messages`;
  const headers = {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
  };

  // ── Strategy 1: Template message try karo ──────────────────────
  try {
    const templateRes = await axios.post(
      url,
      {
        messaging_product: "whatsapp",
        to: formattedNumber,
        type: "template",
        template: {
          name: "weekly_family_update",
          language: { code: "hi" },
          components: [
            {
              type: "body",
              parameters: [
                { type: "text", text: memberName },
                { type: "text", text: elderName },
                { type: "text", text: summary },
              ],
            },
          ],
        },
      },
      { headers }
    );

    console.log(`✅ Template message sent to ${memberName} (${formattedNumber})`);
    return templateRes.data;
  } catch (templateErr) {
    const errData = templateErr.response?.data?.error;
    console.warn(
      `⚠️  Template send failed for ${memberName}: ${errData?.message || templateErr.message}`
    );
    console.log("🔄 Falling back to plain text message...");
  }

  // ── Strategy 2: Plain text fallback ────────────────────────────
  // (Works only if user has messaged your number in last 24 hours)
  try {
    const greeting = `🙏 *${elderName} ka Hafte ka Haal-Chaal*\n\n`;
    const footer = `\n\n— _Parivaar Bridge by SnehSaathi_ 💛`;
    const fullMessage = `Namaste ${memberName} ji,\n\n${greeting}${summary}${footer}`;

    const textRes = await axios.post(
      url,
      {
        messaging_product: "whatsapp",
        to: formattedNumber,
        type: "text",
        text: { body: fullMessage },
      },
      { headers }
    );

    console.log(`✅ Text message sent to ${memberName} (${formattedNumber})`);
    return textRes.data;
  } catch (textErr) {
    console.error(
      `❌ Text message bhi fail hua for ${memberName}:`,
      textErr.response?.data || textErr.message
    );
    throw textErr;
  }
}

/**
 * Test message bhejne ka utility — setup verify karne ke liye
 */
export async function sendTestMessage(phoneNumber) {
  const formattedNumber = phoneNumber.replace(/\D/g, "");
  const phoneId = process.env.PHONE_ID;
  const token = process.env.WHATSAPP_TOKEN;

  const url = `${GRAPH_API}/${phoneId}/messages`;

  const res = await axios.post(
    url,
    {
      messaging_product: "whatsapp",
      to: formattedNumber,
      type: "text",
      text: {
        body: "🕊️ SnehSaathi Parivaar Bridge is alive!\n\nYe test message hai — weekly ghostwriter sahi se kaam kar raha hai. 💛",
      },
    },
    {
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
    }
  );

  console.log("✅ Test message sent!", res.data);
  return res.data;
}
