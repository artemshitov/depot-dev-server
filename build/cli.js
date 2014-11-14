var ARGV, server;

ARGV = require('minimist')(process.argv.slice(2));

server = require('./index');

server.run(ARGV.directory, ARGV.port);
