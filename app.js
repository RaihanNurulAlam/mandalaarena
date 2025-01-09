const express = require('express');
const app = express();
const PORT = 3000;
const path = require('path');
const { midtrans } = require('./controllers/midtrans.controllers');

app.set('view engine', 'ejs');
app.use(express.static(path.join(__dirname, 'views')));
app.use(express.json()); // Tambahkan ini untuk parsing JSON
app.use(express.urlencoded({ extended: true })); // Tambahkan ini untuk parsing URL Encoded

app.get('/', (req, res) => {
    const { totalPrice, userName, userEmail, userPhone } = req.query;
    res.render('form.ejs', { totalPrice, userName, userEmail, userPhone });
});

app.post('/pay', midtrans);

app.listen(PORT, () => console.log('Running on port', PORT));