ARGV = require('minimist')(process.argv[2..])

server = require './index'

server.run ARGV.directory, ARGV.port
