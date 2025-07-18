const express = require('express');
const path = require('path');

const app = express();
const port = 3000;

// Всё из public отдаём как статику
app.use(express.static(path.join(__dirname, 'public')));

app.listen(port, () => {
  console.log(`Сервер запущен: http://localhost:${port}`);
});
