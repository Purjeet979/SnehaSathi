const https = require('https');

const apiKey = process.env.SARVAM_API_KEY;
if (!apiKey) {
  console.error('Missing SARVAM_API_KEY environment variable.');
  process.exit(1);
}

const data = JSON.stringify({
  model: 'sarvam-30b',
  messages: [
    {"role": "system", "content": "You are Sneh Saathi, a warm and caring AI companion for elderly Indians. You must respond in a mix of Hindi and English (Hinglish) using Devanagari script for Hindi words. Be extremely kind, patient, and caring."},
    {"role": "user", "content": "मैं बहुत दुखी हूँ"}
  ],
  max_tokens: 300
});

const options = {
  hostname: 'api.sarvam.ai',
  port: 443,
  path: '/v1/chat/completions',
  method: 'POST',
  headers: {
    'api-subscription-key': apiKey,
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(data)
  }
};

const req = https.request(options, (res) => {
  let resData = '';
  res.on('data', (d) => {
    resData += d;
  });
  res.on('end', () => {
    console.log('Status Code:', res.statusCode);
    console.log('Response:', resData);
  });
});

req.on('error', (error) => {
  console.error(error);
});

req.setTimeout(30000, () => {
  req.destroy(new Error('Sarvam request timed out after 30 seconds'));
});

req.write(data);
req.end();
