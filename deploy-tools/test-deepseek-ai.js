const https = require('https');

function testDeepSeekAI() {
  const apiKey = process.env.DEEPSEEK_API_KEY || 'SET_YOUR_KEY_HERE';
  const topic = 'Stock market intraday trading strategies for beginners';
  const language = 'Hindi';
  const tone = 'natural';
  const count = 5;

  const prompt = `Generate exactly ${count} completely distinct, authentic, natural, human-like comments for a social media / YouTube video.
- Topic / Keywords: "${topic}"
- Language: "${language}" (write naturally in Roman script or Devanagari based on common YouTube usage)
- Tone: "${tone}"

Rules:
1. Every comment MUST be distinct in wording, structure, length, and sentiment from all other comments.
2. Comments must sound like genuine human community members and active viewers, NOT robotic bots.
3. Return ONLY a valid JSON array of ${count} strings without any markdown code blocks, backticks, or extra explanation.
Example format:
["First comment text here", "Second unique comment text here"]`;

  const payload = JSON.stringify({
    model: 'deepseek-chat',
    messages: [
      {
        role: 'system',
        content: 'You are an expert social media community member and engagement writer. You generate genuine, human-like, unique comments and reviews. Always return ONLY a raw JSON array of strings.',
      },
      {
        role: 'user',
        content: prompt,
      },
    ],
    temperature: 0.85,
    max_tokens: 500,
  });

  const options = {
    hostname: 'api.deepseek.com',
    path: '/chat/completions',
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(payload),
    },
  };

  console.log('Sending request to DeepSeek API...');
  const startTime = Date.now();

  const req = https.request(options, (res) => {
    let data = '';
    res.on('data', (chunk) => (data += chunk));
    res.on('end', () => {
      console.log(`Response received in ${Date.now() - startTime}ms (Status: ${res.statusCode}):`);
      try {
        const json = JSON.parse(data);
        if (json.error) {
          console.error('DeepSeek Error:', json.error);
          return;
        }
        const rawContent = json.choices[0].message.content;
        console.log('Raw Content:', rawContent);
        const clean = rawContent
          .replace(/^```json\s*/i, '')
          .replace(/^```\s*/i, '')
          .replace(/\s*```$/i, '')
          .trim();
        const comments = JSON.parse(clean);
        console.log('\n--- Successfully Parsed Comments ---');
        comments.forEach((c, idx) => console.log(`[${idx + 1}] ${c}`));
      } catch (err) {
        console.error('Parse error:', err, 'Data:', data);
      }
    });
  });

  req.on('error', (e) => {
    console.error('Request error:', e);
  });

  req.write(payload);
  req.end();
}

testDeepSeekAI();
