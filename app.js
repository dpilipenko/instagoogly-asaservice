var express = require('express');
var multer = require('multer');
var upload = multer({dest: 'uploads/'});
var port = process.env.PORT || 8080;
var app = express();
app.use(express.static(__dirname + '/public'));

app.get('/', function (res, req) {
  return res.render('index');
});

app.post('/upload', upload.single('file'), function (req, res, next) {
  console.log('image uploaded: ', req.file);

  var options = {
    root: __dirname + '/uploads/',
    dotfiles: 'deny',
    headers: {
      'x-timestamp': Date.now(),
      'x-sent': true
    }
  };

  res.type(req.file.mimetype);
  res.sendFile(req.file.filename, options, function (err) {
    if (err) {
      console.log('err: ', err);
      res.status(err.status).end();
    } else {
      console.log('sent: ', req.file.filename);
    }
  });
});

app.listen(port);
console.log('running on http://localhost:' + port);

