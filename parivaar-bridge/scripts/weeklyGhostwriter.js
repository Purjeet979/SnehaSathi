/*******************************************************************************
 * 🕊️  PARIVAAR BRIDGE — Weekly Ghostwriter
 * 
 * Har Sunday 8 PM IST pe ye script chalta hai:
 * 1. Firestore se pichle 7 din ki conversations padhta hai
 * 2. Sarvam AI se emotional summary banata hai  
 * 3. WhatsApp Cloud API se family members ko bhejta hai
 * 4. Summary ko Firestore mein save karta hai (records ke liye)
 * 
 * Free tier pe poora kaam hota hai — GitHub Actions + Firebase + Sarvam + WhatsApp
 ******************************************************************************/

import admin from "firebase-admin";
import { generateSummary } from "./ghostwriter.js";
import { sendWhatsApp } from "./whatsapp.js";

// ── Firebase Initialize ──────────────────────────────────────────────────────
if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
  console.error("❌ FIREBASE_SERVICE_ACCOUNT environment variable missing!");
  console.error("   GitHub Secrets mein add karo: Settings → Secrets → Actions");
  process.exit(1);
}

let serviceAccount;
try {
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
} catch (e) {
  console.error("❌ FIREBASE_SERVICE_ACCOUNT JSON parse fail hua!", e.message);
  console.error("   Ensure the secret contains valid JSON (full service account key).");
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ── Stats tracking ───────────────────────────────────────────────────────────
const stats = {
  eldersProcessed: 0,
  messagesSent: 0,
  messagesFailed: 0,
  summariesGenerated: 0,
};

// ── Main Logic ───────────────────────────────────────────────────────────────
async function main() {
  console.log("╔══════════════════════════════════════════════════╗");
  console.log("║  🕊️  Parivaar Bridge — Weekly Ghostwriter        ║");
  console.log("║  Running at:", new Date().toLocaleString("hi-IN", { timeZone: "Asia/Kolkata" }));
  console.log("╚══════════════════════════════════════════════════╝\n");

  const sevenDaysAgo = admin.firestore.Timestamp.fromMillis(
    Date.now() - 7 * 24 * 60 * 60 * 1000
  );

  // ── Step 1: Fetch all elders ──────────────────────────────────────────────
  const eldersSnap = await db.collection("elders").get();

  if (eldersSnap.empty) {
    console.log("ℹ️  Koi elder nahi mila Firestore mein.");
    console.log("   'elders' collection mein documents add karo.");
    process.exit(0);
  }

  console.log(`👴 ${eldersSnap.size} elder(s) found. Processing...\n`);

  for (const elderDoc of eldersSnap.docs) {
    const elderId = elderDoc.id;
    const elderData = elderDoc.data();
    const elderName = elderData.name || "Dadi/Dada";

    console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
    console.log(`🧓 Elder: ${elderName} (ID: ${elderId})`);

    // ── Step 2: Last 7 days ki conversations ──────────────────────────────
    const convoSnap = await db
      .collection("elders")
      .doc(elderId)
      .collection("conversations")
      .where("createdAt", ">=", sevenDaysAgo)
      .orderBy("createdAt", "asc")
      .get();

    if (convoSnap.empty) {
      console.log(`  ⏭️  No conversations this week. Skipping.\n`);
      continue;
    }

    const conversations = convoSnap.docs.map((d) => d.data());
    console.log(`  💬 ${conversations.length} conversation(s) found in last 7 days.`);

    // ── Step 3: Sarvam AI se summary generate karo ────────────────────────
    console.log(`  🤖 Generating emotional summary via Sarvam AI...`);
    const summary = await generateSummary(conversations, elderName);
    stats.summariesGenerated++;

    console.log(`  📝 Summary ready (${summary.length} chars)`);
    console.log(`  ┌──────────────────────────────────────┐`);
    console.log(`  │ ${summary.substring(0, 80)}...`);
    console.log(`  └──────────────────────────────────────┘`);

    // ── Step 4: Family members ko WhatsApp bhejo ──────────────────────────
    const familySnap = await db
      .collection("elders")
      .doc(elderId)
      .collection("familyMembers")
      .get();

    if (familySnap.empty) {
      console.log(`  ℹ️  No family members registered for ${elderName}.`);
    }

    for (const memberDoc of familySnap.docs) {
      const member = memberDoc.data();
      const memberName = member.name || "Family Member";

      if (!member.whatsappNo) {
        console.log(`  ⚠️  ${memberName} ka WhatsApp number missing, skipping.`);
        continue;
      }

      try {
        await sendWhatsApp(member.whatsappNo, summary, memberName, elderName);
        stats.messagesSent++;
        console.log(`  📤 ✅ Sent to ${memberName} (${member.whatsappNo})`);
      } catch (err) {
        stats.messagesFailed++;
        console.error(
          `  📤 ❌ Failed for ${memberName}:`,
          err.response?.data?.error?.message || err.message
        );
      }
    }

    // ── Step 5: Summary save karo (records ke liye) ───────────────────────
    await db
      .collection("elders")
      .doc(elderId)
      .collection("weeklySummaries")
      .add({
        summary,
        generatedAt: admin.firestore.Timestamp.now(),
        conversationCount: conversations.length,
        familyMembersNotified: stats.messagesSent,
        weekStart: sevenDaysAgo,
        weekEnd: admin.firestore.Timestamp.now(),
      });

    console.log(`  💾 Summary saved to Firestore.\n`);
    stats.eldersProcessed++;
  }

  // ── Final Report ────────────────────────────────────────────────────────
  console.log(`\n╔══════════════════════════════════════════════════╗`);
  console.log(`║  📊 Weekly Ghostwriter — Summary Report          ║`);
  console.log(`╠══════════════════════════════════════════════════╣`);
  console.log(`║  👴 Elders processed:     ${String(stats.eldersProcessed).padStart(4)}`);
  console.log(`║  📝 Summaries generated:  ${String(stats.summariesGenerated).padStart(4)}`);
  console.log(`║  📤 Messages sent:        ${String(stats.messagesSent).padStart(4)}`);
  console.log(`║  ❌ Messages failed:      ${String(stats.messagesFailed).padStart(4)}`);
  console.log(`╚══════════════════════════════════════════════════╝`);

  if (stats.messagesFailed > 0) {
    console.log("\n⚠️  Some messages failed. Check errors above.");
    process.exit(1);
  }

  console.log("\n✅ Parivaar Bridge ran successfully! 💛\n");
  process.exit(0);
}

main().catch((err) => {
  console.error("\n💥 CRITICAL ERROR:", err.message);
  console.error(err.stack);
  process.exit(1);
});
