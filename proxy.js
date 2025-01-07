// filepath: /d:/mandalaarena-1/proxy.js
const express = require('express');
const request = require('request');
const app = express();
const port = 3000;
const cors = require('cors');

app.use(cors());
app.use(express.json());

app.post('/midtrans', (req, res) => {
  const options = {
    url: 'https://app.sandbox.midtrans.com/snap/v1/transactions',
    method: 'POST',
    headers: {
      'Authorization': `Basic ${Buffer.from('SB-Mid-server-cy93tLqGdUiBnvuFQXhVjlH-:').toString('base64')}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(req.body)
  };

  request(options, (error, response, body) => {
    if (error) {
      res.status(500).send(error);
    } else {
      res.status(response.statusCode).send(body);
    }
  });
});

app.listen(port, () => {
  console.log(`Proxy server running at http://localhost:${port}`);
});