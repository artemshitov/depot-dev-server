fs = require 'fs'
Promise = require 'bluebird'

module.exports = (filePath) ->
  new Promise (resolve, reject) ->
    fs.exists filePath, (exists) ->
      resolve exists
