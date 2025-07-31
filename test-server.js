const http = require('http');

const server = http.createServer((req, res) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url} - Host: ${req.headers.host}`);
  
  res.writeHead(200, { 
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*'
  });
  
  res.end(JSON.stringify({
    message: 'strangematic.com tunnel test',
    timestamp: new Date().toISOString(),
    host: req.headers.host,
    url: req.url,
    method: req.method,
    headers: req.headers
  }, null, 2));
});

server.listen(8080, '0.0.0.0', () => {
  console.log('Test server running on http://localhost:8080');
});
