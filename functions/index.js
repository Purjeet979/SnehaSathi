require("dotenv").config();
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const twilio = require("twilio");

admin.initializeApp();
const db = admin.firestore();

const TWILIO_SID = process.env.TWILIO_SID;
const TWILIO_AUTH_TOKEN = process.env.TWILIO_AUTH_TOKEN;
const TWILIO_PHONE_NUMBER = "+1234567890"; // Placeholder
const SARVAM_API_KEY = process.env.SARVAM_API_KEY;

const twilioClient = twilio(TWILIO_SID, TWILIO_AUTH_TOKEN);

exports.weeklyGhostwriter = functions.pubsub
  .schedule("every monday 09:00")
  .timeZone("Asia/Kolkata")
  .onRun(async (context) => {
    const usersSnap = await db.collection("users").get();

    for (const userDoc of usersSnap.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();

      // Get this week's conversations (mocked for hackathon from daily_summaries)
      const oneWeekAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
      const convSnap = await db
        .collection("daily_summaries")
        .where("timestamp", ">", oneWeekAgo)
        .get();

      const convText = convSnap.docs
        .map((d) => d.data().text)
        .join("\n");

      if (!convText) continue;

      // Generate Dadi's letter using Sarvam LLM
      const letterResponse = await axios.post(
        "https://api.sarvam.ai/chat/completions",
        {
          model: "sarvam-2b-v0.5",
          messages: [
            {
              role: "system",
              content: `Tum ek elderly Indian dadi ho. Neeche diye conversations ke
              base par apne bete/beti ko ek pyara letter likho — unki awaaz mein,
              Hinglish mein, 4-5 sentences mein. Personal aur emotional hona chahiye.`,
            },
            { role: "user", content: convText },
          ],
        },
        { headers: { "api-subscription-key": SARVAM_API_KEY } }
      );

      const hindiLetter = letterResponse.data.choices[0].message.content;

      // Send translated versions to each family member
      for (const member of userData.family_contacts || []) {
        let finalLetter = hindiLetter;

        // Translate if family member prefers different language
        if (member.language && member.language !== "hi-IN") {
          try {
            const transResponse = await axios.post(
              "https://api.sarvam.ai/translate",
              {
                input: hindiLetter,
                source_language_code: "hi-IN",
                target_language_code: member.language,
                model: "mayura:v1",
              },
              {
                headers: { "api-subscription-key": SARVAM_API_KEY },
              }
            );
            finalLetter = transResponse.data.translated_text;
          } catch (e) {
            console.error("Translation failed", e.response?.data || e.message);
          }
        }

        // Send via WhatsApp (Twilio)
        try {
          await twilioClient.messages.create({
            body: finalLetter,
            to: member.phone, // "whatsapp:+919876543210"
            from: TWILIO_PHONE_NUMBER // "whatsapp:+14155238886"
          });
        } catch(e) {
            console.error("Twilio failed", e.message);
        }

        // Store in Firestore for family portal
        await db.collection(`users/${userId}/ghostwriter_letters`).add({
          recipient: member.name || "Family",
          language: member.language || "hi-IN",
          letter: finalLetter,
          timestamp: Date.now(),
        });
      }
    }
  });
