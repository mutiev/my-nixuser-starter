#!/usr/bin/env node

const express = require('express');
const path = require('path');
const fs = require('fs');
const open = require('open');


const app = express();
const port = 3250;

app.use(express.urlencoded({ extended: true }));

// Каталоги и скрипты с описаниями
const FOLDERS = {
  "apps": "Живые сервисы, отдельные каталоги для каждого (node-red, icecast, autossh и др.)",
  "scripts": "Утилиты, стартеры, деплой и вспомогательные скрипты",
  "build-sources": "Исходники для сборки (ffmpeg, кастомные бинарники и т.д.)",
  "bin": "Твои собранные/скачанные бинарники",
  "data": "Базы, дампы, временные файлы",
  "config": "Конфиги и .env, шаблоны настроек",
  "docs": "Markdown-инструкции, заметки, howto",
  "logs": "Логи сервисов",
  "public": "Открытая статика (если нужно раздавать через nginx и т.п.)",
  "locales": "Файлы переводов (если планируешь мультиязычность)",
  "legacy": "Архив старого мусора и бэкапы"
};

const SCRIPTS = {
  "scripts/restart-all.sh": "Рестарт всех сервисов",
  "scripts/backup.sh": "Бэкап пользовательских данных/сервисов",
  "scripts/menu.sh": "Главное меню или entrypoint для быстрого управления",
  "scripts/build-ffmpeg.sh": "Скрипт сборки ffmpeg (или другого крупного бинаря)"
};

// Главная страница — чекбоксы, что создавать
app.get('/', (req, res) => {
  const pwd = process.cwd();
  let foldersForm = '';
  for (const [folder, desc] of Object.entries(FOLDERS)) {
    const exists = fs.existsSync(path.join(pwd, folder));
    foldersForm += `<label><input type="checkbox" name="folders" value="${folder}" ${exists ? 'checked' : ''}> ${folder} ${exists ? '✅' : ''}<span style="color:#888"> — ${desc}</span></label><br>`;
  }
  let scriptsForm = '';
  for (const [script, desc] of Object.entries(SCRIPTS)) {
    const exists = fs.existsSync(path.join(pwd, script));
    scriptsForm += `<label><input type="checkbox" name="scripts" value="${script}" ${exists ? 'checked' : ''}> ${script} ${exists ? '✅' : ''}<span style="color:#888"> — ${desc}</span></label><br>`;
  }

  res.send(`
    <html>
      <head>
        <title>Cookiecutter infra (Express UI)</title>
        <meta charset="utf-8"/>
        <style>
          body { font-family: monospace; padding:2rem; }
          .block { margin-bottom:2rem;}
          label { display:block; margin-bottom:0.5rem;}
          h2 { margin-bottom:1rem;}
        </style>
      </head>
      <body>
        <h1>💡 Cookiecutter инфраструктуры</h1>
        <form method="POST">
          <div class="block">
            <h2>Каталоги</h2>
            ${foldersForm}
          </div>
          <div class="block">
            <h2>Рекомендуемые скрипты</h2>
            ${scriptsForm}
          </div>
          <button type="submit">Создать отмеченное</button>
        </form>
        <hr>
        <p style="color: #555;">P.S. После создания новых каталогов — положи в каждый README.md, чтобы не забыть для чего он.<br>
        Пример создания вручную: <code>mkdir -p apps scripts build-sources bin data config docs logs public locales legacy</code></p>
      </body>
    </html>
  `);
});

// POST: создать выбранные каталоги и пустые скрипты
app.post('/', (req, res) => {
  let body = '';
  req.on('data', chunk => { body += chunk; });
  req.on('end', () => {
    const params = new URLSearchParams(body);
    const created = [];

    // Каталоги
    for (const folder of params.getAll('folders')) {
      const dir = path.join(process.cwd(), folder);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
        created.push(`Каталог <b>${folder}</b> создан`);
      }
    }

    // Скрипты
    for (const script of params.getAll('scripts')) {
      const file = path.join(process.cwd(), script);
      const dir = path.dirname(file);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      if (!fs.existsSync(file)) {
        fs.writeFileSync(file, "#!/bin/bash\n\n# TODO: Напиши сюда свой скрипт\n", { mode: 0o755 });
        created.push(`Скрипт <b>${script}</b> создан`);
      }
    }

    res.send(`
      <html>
        <head>
          <meta charset="utf-8"/>
          <style>body{font-family:monospace;padding:2rem}</style>
        </head>
        <body>
          <h2>Результат:</h2>
          <ul>
            ${created.length ? created.map(c => `<li>${c}</li>`).join('') : '<li>Ничего не создано — всё уже было</li>'}
          </ul>
          <a href="/">⬅ Вернуться назад</a>
        </body>
      </html>
    `);
  });
});

// Стартуем сервер
app.listen(port, () => {
  console.log(`Открой в браузере: http://localhost:${port}`);
//   open(`http://localhost:${port}`);
});
