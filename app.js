const http = require('http');
http.createServer((req, res) => {
  res.end('Server running!');
}).listen(3000, () => console.log('Server started'));