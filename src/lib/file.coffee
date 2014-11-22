fs = require 'fs'
Promise = require 'bluebird'

util = require './util'
fsExists = require './fs-exists'


ctime = (filePath) ->
  Promise.promisify(fs.stat)(filePath)
    .then (stats) ->
      stats.ctime.getTime()

existsAny = (filePaths) ->
  Promise.any(filePaths.map(fsExists))

module.exports = {
  ctime
  existsAny
}
