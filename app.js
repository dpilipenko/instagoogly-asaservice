var express = require('express');
var port = process.env.PORT || 8080;
var app = express();
app.use(express.static(__dirname + '/public'));

app.get('/', function (res, req) {
  return res.render('index');
});

app.listen(port);
console.log('running on http://localhost:' + port);

