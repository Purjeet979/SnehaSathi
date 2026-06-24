# 🕊️ Parivaar Bridge — Weekly Ghostwriter

> *Har hafte, buzurgon ki baatein... unke pyaaron tak.*

Ye system automatically:
1. **Firestore se** pichle 7 din ki conversations padhta hai
2. **Sarvam AI se** emotional, heart-touching summary generate karta hai
3. **WhatsApp Cloud API se** family members ko bhejta hai
4. **Firestore mein** summary save karta hai (records ke liye)

Poora system **free tier** pe chalta hai — GitHub Actions + Firebase + Sarvam AI + WhatsApp.

---

## 📁 Project Structure

```
parivaar-bridge/
├── scripts/
│   ├── weeklyGhostwriter.js   ← Main orchestrator (runs every Sunday)
│   ├── ghostwriter.js          ← Sarvam AI summary generator
│   ├── whatsapp.js             ← WhatsApp Cloud API integration
│   └── testLocal.js            ← Local testing script
├── package.json
└── README.md
```

GitHub Actions workflow is at repo root:
```
.github/workflows/weekly-summary.yml
```

---

## 🔧 Setup Instructions

### Step 1: GitHub Secrets Add Karo

Repository Settings → Secrets and variables → Actions → **New repository secret**

| Secret Name               | Value                                                    |
|---------------------------|----------------------------------------------------------|
| `FIREBASE_SERVICE_ACCOUNT`| Full JSON content of your Firebase service account key   |
| `SARVAM_API_KEY`          | Sarvam AI API key (e.g., `sk_xxxxx`)                     |
| `WHATSAPP_TOKEN`          | WhatsApp Cloud API access token                          |
| `PHONE_ID`                | WhatsApp Phone Number ID (e.g., `1130770773459500`)      |

### Step 2: WhatsApp Template (Optional)

Meta Business Suite mein ek template banao:
- **Name**: `weekly_family_update`
- **Language**: Hindi
- **Body**: `Namaste {{1}}, {{2}} ka is hafte ka haal-chaal: {{3}}`
- 3 text parameters: Family Member Name, Elder Name, Summary

> ℹ️ Template approval mein time lagta hai. Tab tak system **plain text messages** bhejega (works if user has messaged your number in last 24 hours).

### Step 3: Firestore Structure

```
elders/
  └── {elderId}/
      ├── name: "Dadi"
      ├── conversations/
      │   └── {convoId}/
      │       ├── messageText: "..."
      │       ├── emotionTag: "happy"
      │       ├── speaker: "Dadi"
      │       └── createdAt: Timestamp
      ├── familyMembers/
      │   └── {memberId}/
      │       ├── name: "Rohan"
      │       └── whatsappNo: "918390346801"
      └── weeklySummaries/  ← Auto-created by script
          └── {summaryId}/
              ├── summary: "..."
              ├── generatedAt: Timestamp
              └── conversationCount: 12
```

### Step 4: Push & Test

```bash
# Push to GitHub
git add .
git commit -m "🕊️ Add Parivaar Bridge weekly ghostwriter"
git push origin main

# Manual test — GitHub Actions tab mein jaao → Weekly Ghostwriter → Run workflow
```

---

## 🧪 Local Testing

```bash
cd parivaar-bridge
npm install

# Set environment variables
export WHATSAPP_TOKEN="your-access-token"
export PHONE_ID="1130770773459500"
export SARVAM_API_KEY="sk_xxxxx"

# Run test
npm run test:local
```

---

## ⏰ Schedule

| When            | What                        |
|-----------------|-----------------------------|
| Every Sunday    | 8:00 PM IST (2:30 PM UTC)  |
| Manual trigger  | Actions tab → Run workflow  |

---

## 💰 Cost

| Service         | Free Tier Used                    |
|-----------------|-----------------------------------|
| GitHub Actions  | 2000 min/month (uses ~2 min/week) |
| Firebase        | Spark plan (50K reads/day)        |
| Sarvam AI       | Free tier API calls               |
| WhatsApp        | 1000 free conversations/month     |

**Total cost: ₹0** 🎉

---

## 🛡️ Security Notes

- Access tokens ko **kabhi code mein hardcode mat karo** — GitHub Secrets use karo
- `serviceAccountKey.json` ko `.gitignore` mein rakho
- WhatsApp access token har 60 days expire hota hai — Meta dashboard se renew karo

---

*Made with 💛 for SnehSaathi — kyunki har buzurg ki kahani, uske ghar tak pahuchni chahiye.*
