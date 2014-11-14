fs = require 'fs'
Promise = require 'bluebird'

util = require './util'

fsExists = Promise.promisify(require 'fs-exists')

ctime = (filePath) ->
  Promise.promisify(fs.stat)(filePath)
    .then (stats) ->
      stats.ctime.getTime()

existsAlternative = (filePaths) ->
  Promise.map filePaths, (filePath) ->
    fsExists filePath
      .then (exists) ->
        [filePath, exists]
  .then (results) ->
    util.findFirst (([filePath, exists]) -> exists), results
  .then (result) ->
    if result? then result[0]
    else undefined


module.exports = {
  ctime
  existsAlternative
}
