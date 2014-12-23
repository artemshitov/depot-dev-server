ARGV = require('minimist')(process.argv[2..])

server = require './index'
version = require('../package.json').version

directory = ARGV.directory || process.cwd()
port      = ARGV.port || 3030

app = server.createServer directory
app.listen port, ->
  console.log "Depot development server, version #{version}"
  console.log "Listening on port #{port}"
