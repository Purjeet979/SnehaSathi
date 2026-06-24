import axios from "axios";

const SARVAM_API = "https://api.sarvam.ai/v1/chat/completions";

/**
 * Sarvam AI se weekly emotional summary generate karta hai.
 * 
 * Conversations ka transcript banakar ek warm, heart-touching
 * Hinglish summary likha jaata hai — jo family members ko
 * buzurg ka haal-chaal emotional tareeke se batata hai.
 */
export async function generateSummary(conversations, elderName) {
  const apiKey = process.env.SARVAM_API_KEY;

  if (!apiKey) {
    throw new Error("❌ SARVAM_API_KEY environment variable missing hai!");
  }

  // Build transcript from conversations
  const transcript = conversations
    .map((c) => {
      const emotion = c.emotionTag || c.emotion || "neutral";
      const speaker = c.speaker || (c.isUser ? elderName : "SnehSaathi");
      const text = c.messageText || c.text || c.message || "";
      const time = c.createdAt?._seconds
        ? new Date(c.createdAt._seconds * 1000).toLocaleDateString("hi-IN")
        : "";
      return `[${emotion}]${time ? ` (${time})` : ""} ${speaker}: ${text}`;
    })
    .filter((line) => line.trim().length > 10) // Skip empty/tiny entries
    .join("\n");

  if (!transcript || transcript.length < 20) {
    return `${elderName} is hafte shant rahe, lekin unki sehat theek hai. Ek baar call kar lijiye — unhe bahut accha lagega. 💛`;
  }

  const prompt = `
Tum ek caring family member ho jo ghar ke buzurg (${elderName}) ka
haal-chaal baaki parivaar ko bata rahe ho — jaise ek letter likh rahe ho.

Neeche pichle 7 din ki baat-cheet ka transcript hai. Isse padhkar ek WARM, EMOTIONAL aur
HUMAN-LIKE weekly summary likho.

━━━ RULES ━━━
• Simple Hindi/Hinglish mein likho (ghar jaisa tone, dil se likha hua)
• ${elderName} ke mood, yaadein, health ke baare mein gently mention karo
• Agar lonely ya kisi ko miss kar rahe hain — pyaar se batao  
• Koi khushi ya mazedaar baat hui ho — wo bhi share karo 😊
• Ek heart-touching closing line likho jo family ko call/visit karne ko prerit kare
• 100-150 words mein likho (zyada lamba nahi)
• Thoda emoji use karo — lekin natural rakho
• Koi greeting/salutation mat likho — seedha content do

━━━ TRANSCRIPT ━━━
${transcript}
`;

  try {
    const response = await axios.post(
      SARVAM_API,
      {
        model: "sarvam-m",
        messages: [
          {
            role: "system",
            content:
              "Tum ek caring Indian family member ho. Tumhe buzurgon ka haal-chaal emotional, warm aur real tareeke se batana aata hai. Tumhari likhai mein pyaar dikhta hai.",
          },
          { role: "user", content: prompt },
        ],
        temperature: 0.8,
        max_tokens: 600,
      },
      {
        headers: {
          "api-subscription-key": apiKey,
          "Content-Type": "application/json",
        },
      }
    );

    const summary = response.data?.choices?.[0]?.message?.content;

    if (!summary) {
      console.warn("⚠️  Sarvam AI ne empty response diya. Fallback use ho raha hai.");
      return `${elderName} is hafte acche rahe. Unse baat karna na bhoolein — aapki ek call unka poora din bana deti hai. 💛`;
    }

    return summary.trim();
  } catch (err) {
    const errMsg = err.response?.data?.error?.message || err.response?.data || err.message;
    console.error("❌ Sarvam AI Error:", errMsg);

    // Graceful fallback — still send something meaningful
    console.log("🔄 Using fallback summary...");
    return `${elderName} se is hafte humne kai baatein ki. Unki tabiyat theek hai, lekin aapki awaaz sunne ka mann kar raha hai. Jab time mile, ek chhoti si call kar lijiye — unke chehre pe muskaan aa jayegi. 🙏💛`;
  }
}
