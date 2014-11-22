fs = require 'fs'
Promise = require 'bluebird'

module.exports = (filePath) ->
  new Promise (resolve, reject) ->
    fs.exists filePath, (exists) ->
      if exists
        resolve filePath
      else
        reject new Error('File does not exist')
