const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send(`
    <html><body style='background:#1a237e;color:white;font-family:Arial;text-align:center;padding:50px'>
      <h1>🔵 BLUE Version</h1>
      <h2>Version: 1.0.0</h2>
      <p>Student: Aakash E | RA2311026010022</p>
      <p>This is the CURRENT PRODUCTION environment</p>
      <p>Hostname: ${require('os').hostname()}</p>
      <p>Time: ${new Date().toISOString()}</p>
    </body></html>
  `);
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', color: 'blue', version: '1.0.0' });
});

app.listen(PORT, () => console.log(`Blue app on port ${PORT}`));
