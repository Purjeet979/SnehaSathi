import axios from "axios";

const GRAPH_API = "https://graph.facebook.com/v21.0";
const REQUEST_TIMEOUT_MS = 30000;

function getWhatsAppConfig() {
  const phoneId = process.env.PHONE_ID;
  const token = process.env.WHATSAPP_TOKEN;
  const templateName = process.env.WHATSAPP_TEMPLATE_NAME || "weekly_family_update";

  if (!phoneId || !token) {
    throw new Error("PHONE_ID or WHATSAPP_TOKEN environment variable is missing.");
  }

  return { phoneId, token, templateName };
}

function requestHeaders(token) {
  return {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
  };
}

export async function sendWhatsApp(phoneNumber, summary, memberName, elderName) {
  const formattedNumber = phoneNumber.replace(/\D/g, "");
  const { phoneId, token, templateName } = getWhatsAppConfig();
  const url = `${GRAPH_API}/${phoneId}/messages`;

  try {
    const templateRes = await axios.post(
      url,
      {
        messaging_product: "whatsapp",
        to: formattedNumber,
        type: "template",
        template: {
          name: templateName,
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
      {
        headers: requestHeaders(token),
        timeout: REQUEST_TIMEOUT_MS,
      }
    );

    console.log(`WhatsApp template message sent to ${memberName} (${formattedNumber})`);
    return templateRes.data;
  } catch (error) {
    const graphError = error.response?.data?.error;
    console.error(
      `WhatsApp template send failed for ${memberName}: ${graphError?.message || error.message}`,
      graphError || ""
    );
    throw error;
  }
}

export async function sendTestMessage(phoneNumber) {
  const formattedNumber = phoneNumber.replace(/\D/g, "");
  const { phoneId, token } = getWhatsAppConfig();
  const url = `${GRAPH_API}/${phoneId}/messages`;

  const response = await axios.post(
    url,
    {
      messaging_product: "whatsapp",
      to: formattedNumber,
      type: "text",
      text: {
        body: "SnehSaathi Parivaar Bridge test message.",
      },
    },
    {
      headers: requestHeaders(token),
      timeout: REQUEST_TIMEOUT_MS,
    }
  );

  console.log("WhatsApp test message sent.", response.data);
  return response.data;
}
