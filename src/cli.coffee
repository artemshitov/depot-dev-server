ARGV = require('minimist')(process.argv[2..])

server = require './index'

directory = ARGV.directory || process.cwd()
port      = ARGV.port || 3030

app = server.createServer directory
app.listen port
console.log "Listening on port #{port}"
