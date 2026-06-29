/***********************
 * GRANDMA'S GHOSTWRITER
 * Local Demo Script (Groq)
 ***********************/

require("dotenv").config();

const admin = require("firebase-admin");
const twilio = require("twilio");
const Groq = require("groq-sdk");

// 🔹 Firebase Admin
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// 🔹 Twilio
const client = twilio(
  process.env.TWILIO_SID,
  process.env.TWILIO_AUTH_TOKEN
);

// 🔹 Groq
const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY,
});

// 🔹 Fetch summaries
async function fetchSummaries() {
  const snapshot = await db
    .collection("daily_summaries")
    .orderBy("timestamp", "desc")
    .limit(7)
    .get();

  return snapshot.docs.map(d => d.data().text);
}

// 🔹 Generate letter with Groq
async function generateWeeklyLetter(dailySummaries) {
  const prompt = `
You are Dadi, an elderly Indian grandmother writing to your grandson Rohan.
Write a warm, emotional 100-word letter in Hinglish.
Mention health gently, food, memories, and missing him.

Weekly notes:
${dailySummaries.join("\n")}
`;

  const completion = await groq.chat.completions.create({
    model: "llama-3.1-8b-instant",
    messages: [
      { role: "system", content: "You are a loving Indian grandmother." },
      { role: "user", content: prompt },
    ],
  });

  return completion.choices[0].message.content;
}

// 🔹 Send WhatsApp
async function sendWhatsApp(message) {
  await client.messages.create({
    from: process.env.TWILIO_WHATSAPP_FROM || "whatsapp:+14155238886", // Twilio sandbox
    to: process.env.TWILIO_WHATSAPP_TO || "whatsapp:+##",
    body: message,
  });

  console.log("✅ WhatsApp message sent successfully");
}

// 🔹 RUN
async function runGhostwriter() {
  console.log("📖 Fetching daily summaries from Firestore...");
  const summaries = await fetchSummaries();

  console.log("🤖 Generating letter using Groq...");
  const letter = await generateWeeklyLetter(summaries);

  console.log("📲 Sending WhatsApp message...");
  await sendWhatsApp(letter);
}

runGhostwriter().catch(console.error);
