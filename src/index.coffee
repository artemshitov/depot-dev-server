server    = require './lib/server'

run = (directory = process.cwd(), port = process.env.PORT || 3030) ->
  app = server.createServer directory
  app.listen port
  console.log "Listening on port #{port}"

module.exports = {
  run
}
