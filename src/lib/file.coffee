fs = require 'fs'
Promise = require 'bluebird'
R = require 'ramda'

fsExists = require './fs-exists'


ctime = (filePath) ->
  Promise.promisify(fs.stat)(filePath)
    .then (stats) ->
      stats.ctime.getTime()

existsAny = (filePaths) ->
  Promise.map filePaths, (filePath) ->
    fsExists filePath
      .then (exists) ->
        [filePath, exists]
  .then (results) ->
    R.find (([filePath, exists]) -> exists), results
  .then (result) ->
    if result? then result[0]
    else undefined

module.exports = {
  ctime
  existsAny
}
