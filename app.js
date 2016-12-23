var express = require('express');
var multer = require('multer');
var upload = multer({dest: 'uploads/'});
var port = process.env.PORT || 8080;
var app = express();
app.use(express.static(__dirname + '/public'));

app.get('/', function (res, req) {
  return res.render('index');
});
/* validate file was submitted */
app.post('/upload', upload.single('file'), function (req, res, next) {
  if (req.file) {
    next();
  } else {
    res.status(400).send('no file was submitted');
  }
});

/* validate file is an image */
app.post('/upload', upload.single('file'), function (req, res, next) {
  if ((req.file.mimetype.indexOf('image/jpeg') > -1) || (req.file.mimetype.indexOf('image/gif') > -1) || (req.file.mimetype.indexOf('image/png') > -1)) {
    next();
  } else {
    res.status(400).send('submitted file not an image');
  }
});

/* validate file fits size criteria */
app.post('/upload', upload.single('file'), function (req, res, next) {
  console.log('TODO: implement size validation');
  next();
});

/* transform image and calculate coordinates of faces */
app.post('/upload', upload.single('file'), function (req, res, next) {
  console.log('TODO: implement face detection and append calculated values to req for next middleware');
  next();
});

/* transform image and draw googly-eyes image at coordinates of eyes */
app.post('/upload', upload.single('file'), function (req, res, next) {
  console.log('TODO: implement image manipulation and append updated image to req for next middleware');
  next();
});

/* respond with new image */
app.post('/upload', upload.single('file'), function (req, res, next) {
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
      res.status(err.status).end();
    } else {
      /* done */
    }
  });
});

app.listen(port);
console.log('running on http://localhost:' + port);
