const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send(`
    <html><body style='background:#1b5e20;color:white;font-family:Arial;text-align:center;padding:50px'>
      <h1>🟢 GREEN Version</h1>
      <h2>Version: 2.0.0</h2>
      <p>Student: Aakash E | RA2311026010022</p>
      <p>This is the NEW version being deployed!</p>
      <p>NEW FEATURE: Enhanced performance + Security patches</p>
      <p>Hostname: ${require('os').hostname()}</p>
      <p>Time: ${new Date().toISOString()}</p>
    </body></html>
  `);
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', color: 'green', version: '2.0.0' });
});

app.get('/api/new-feature', (req, res) => {
  res.json({ feature: 'new-endpoint', active: true });
});

app.listen(PORT, () => console.log(`Green app on port ${PORT}`));
