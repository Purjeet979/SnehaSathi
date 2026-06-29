/*******************************************************************************
 * 🧪 LOCAL TEST SCRIPT — Test WhatsApp + Ghostwriter locally
 * 
 * Usage:
 *   1. Set environment variables in a .env file or export them
 *   2. Run: node scripts/testLocal.js
 * 
 * Ye script:
 *   - Firebase se connect hoke real conversations padhta hai
 *   - Sarvam AI se summary generate karta hai
 *   - Ek test WhatsApp message bhejta hai
 ******************************************************************************/

import admin from "firebase-admin";
import { readFileSync, existsSync } from "fs";
import { generateSummary } from "./ghostwriter.js";
import { sendTestMessage, sendWhatsApp } from "./whatsapp.js";

// ── Config ───────────────────────────────────────────────────────────────────
const TEST_PHONE = process.env.TEST_PHONE || "##";  // Set TEST_PHONE env var or replace ##

// ── Firebase Setup (using service account file for local testing) ─────────
let serviceAccount;

if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
} else if (existsSync("../ghostwriter-local/serviceAccountKey.json")) {
  const raw = readFileSync("../ghostwriter-local/serviceAccountKey.json", "utf8");
  serviceAccount = JSON.parse(raw);
} else {
  console.error("❌ No Firebase service account found!");
  console.error("   Either set FIREBASE_SERVICE_ACCOUNT env var or place serviceAccountKey.json");
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ── Set env vars for WhatsApp (if not already set) ───────────────────────
if (!process.env.PHONE_ID) {
  process.env.PHONE_ID = "##";
}
if (!process.env.WHATSAPP_TOKEN) {
  console.error("❌ WHATSAPP_TOKEN environment variable set karo!");
  console.error("   export WHATSAPP_TOKEN='your-access-token-here'");
  process.exit(1);
}
if (!process.env.SARVAM_API_KEY) {
  // Try reading from functions/.env
  if (existsSync("../functions/.env")) {
    const envContent = readFileSync("../functions/.env", "utf8");
    const match = envContent.match(/SARVAM_API_KEY=(.+)/);
    if (match) {
      process.env.SARVAM_API_KEY = match[1].trim();
      console.log("🔑 SARVAM_API_KEY loaded from functions/.env");
    }
  }
}

async function runTest() {
  console.log("╔══════════════════════════════════════════════════╗");
  console.log("║  🧪 Parivaar Bridge — LOCAL TEST                 ║");
  console.log("╚══════════════════════════════════════════════════╝\n");

  // ── Test 1: WhatsApp Connection ────────────────────────────────────────
  console.log("━━━ TEST 1: WhatsApp Connection ━━━");
  try {
    await sendTestMessage(TEST_PHONE);
    console.log("✅ WhatsApp connection works!\n");
  } catch (err) {
    console.error("❌ WhatsApp test failed:", err.response?.data || err.message);
    console.log("   Check WHATSAPP_TOKEN and PHONE_ID\n");
  }

  // ── Test 2: Firestore Read ─────────────────────────────────────────────
  console.log("━━━ TEST 2: Firestore Connection ━━━");
  try {
    const eldersSnap = await db.collection("elders").get();
    console.log(`✅ Found ${eldersSnap.size} elder(s) in Firestore\n`);

    if (eldersSnap.empty) {
      console.log("ℹ️  No elders yet. Creating test data...");
      
      // Provide sample mock conversations for testing
      const mockConversations = [
        {
          emotionTag: "happy",
          speaker: "Dadi",
          messageText: "Aaj garden mein bahut achhe phool khile hain, maine unki photo kheenchi",
          createdAt: admin.firestore.Timestamp.now(),
        },
        {
          emotionTag: "nostalgic",
          speaker: "Dadi", 
          messageText: "Purane zamane mein hum sab saath mein khaana khate the, ab sab busy hain",
          createdAt: admin.firestore.Timestamp.now(),
        },
        {
          emotionTag: "caring",
          speaker: "Dadi",
          messageText: "Rohan beta ka koi phone nahi aaya is hafte, uski padhai kaisi chal rahi hogi",
          createdAt: admin.firestore.Timestamp.now(),
        },
      ];

      console.log("\n━━━ TEST 3: Sarvam AI Summary (with mock data) ━━━");
      const summary = await generateSummary(mockConversations, "Dadi");
      console.log("📝 Generated Summary:");
      console.log("┌──────────────────────────────────────────────────┐");
      console.log(summary);
      console.log("└──────────────────────────────────────────────────┘\n");

      console.log("━━━ TEST 4: Send Summary via WhatsApp ━━━");
      try {
        await sendWhatsApp(TEST_PHONE, summary, "Rohan", "Dadi");
        console.log("✅ Summary message sent!\n");
      } catch (err) {
        console.error("❌ Summary send failed:", err.response?.data?.error?.message || err.message);
      }
    } else {
      // Use real data from first elder
      const firstElder = eldersSnap.docs[0];
      const elderData = firstElder.data();
      const elderName = elderData.name || "Dadi";

      const sevenDaysAgo = admin.firestore.Timestamp.fromMillis(
        Date.now() - 7 * 24 * 60 * 60 * 1000
      );

      const convoSnap = await db
        .collection("elders").doc(firstElder.id)
        .collection("conversations")
        .where("createdAt", ">=", sevenDaysAgo)
        .orderBy("createdAt", "asc")
        .get();

      console.log(`  💬 ${convoSnap.size} conversations in last 7 days for ${elderName}`);

      const conversations = convoSnap.empty
        ? [{ emotionTag: "neutral", speaker: elderName, messageText: "Test conversation" }]
        : convoSnap.docs.map((d) => d.data());

      console.log("\n━━━ TEST 3: Sarvam AI Summary ━━━");
      const summary = await generateSummary(conversations, elderName);
      console.log("📝 Generated Summary:");
      console.log("┌──────────────────────────────────────────────────┐");
      console.log(summary);
      console.log("└──────────────────────────────────────────────────┘\n");

      console.log("━━━ TEST 4: Send Summary via WhatsApp ━━━");
      try {
        await sendWhatsApp(TEST_PHONE, summary, "Rohan", elderName);
        console.log("✅ Summary message sent!\n");
      } catch (err) {
        console.error("❌ Summary send failed:", err.response?.data?.error?.message || err.message);
      }
    }
  } catch (err) {
    console.error("❌ Firestore read failed:", err.message);
  }

  console.log("\n🏁 All tests complete!\n");
  process.exit(0);
}

runTest().catch((err) => {
  console.error("💥 Test crashed:", err);
  process.exit(1);
});
