var express = require('express');
var router = express.Router();

var sqlite3 = require("sqlite3").verbose();
var db = new sqlite3.Database('data.db');
db.run("CREATE TABLE IF NOT EXISTS notes (id INTEGER PRIMARY KEY, title TEXT, body TEXT)");

router.get('/api/notes', function(req, res, next) {
  db.all("SELECT id,title,body FROM notes", function (err, rows) {
    console.log(err, rows);
    res.setHeader('Content-Type', 'application/json');
    res.send(JSON.stringify(rows));
  });
});

router.put('/api/notes', function(req, res, next) {
  db.run('INSERT INTO notes(title,body) VALUES ("' + req.body.title + '", "' + req.body.body + '")', function (err, row) {
    console.log(err, row, req.body);
    res.setHeader('Content-Type', 'application/json');
    res.status(!err ? 200 : 404);
    res.send(JSON.stringify(!err ? true : false));
  });
});

router.post('/api/notes/:id/:field', function(req, res, next) {
  if (req.params.field in { title: true, body: true }) {
    db.run('UPDATE notes SET `' + req.params.field + '`="' + req.body[req.params.field] + '" WHERE `id`="' + req.params.id + '"', function (err, row) {
      console.log(err, row, req.params, req.body);
      res.setHeader('Content-Type', 'application/json');
      res.status(!err ? 200 : 404);
      res.send(JSON.stringify(!err ? true : false));
    });
  } else {
    res.setHeader('Content-Type', 'application/json');
    res.status(404);
    res.send(JSON.stringify(false));
  }
});

router.post('/api/notes/:id', function(req, res, next) {
  db.run('UPDATE notes SET `title`="' + req.body.title + '", `body`="' + req.body.body + '" WHERE `id`="' + req.params.id + '"', function (err, row) {
    console.log(err, row, req.params, req.body);
    res.setHeader('Content-Type', 'application/json');
    res.status(!err ? 200 : 404);
    res.send(JSON.stringify(!err ? true : false));
  });
});

router.delete('/api/notes/:id', function(req, res, next) {
  db.run('DELETE FROM notes WHERE `id`="' + req.params.id + '"', function (err, row) {
    console.log(err, row, req.params);
    res.setHeader('Content-Type', 'application/json');
    res.status(!err ? 200 : 404);
    res.send(JSON.stringify(!err ? true : false));
  });
});

module.exports = router;
