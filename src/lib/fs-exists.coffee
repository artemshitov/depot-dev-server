fs = require 'fs'
Promise = require 'bluebird'

fsExists = (filePath) ->
  new Promise (resolve, reject) ->
    fs.exists filePath, resolve

module.exports = fsExists
