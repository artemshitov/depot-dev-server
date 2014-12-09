fs = require 'fs'
Promise = require 'bluebird'
R = require 'ramda'

fsExists = require './fs-exists'

fsStat = Promise.promisify fs.stat

mtime = R.pPipe fsStat, R.prop('mtime'), R.func('getTime')

existsAny = (filePaths) ->
  if filePaths.length == 0
    Promise.resolve undefined
  else
    fsExists(filePaths[0]).then (exists) ->
      if exists then filePaths[0]
      else existsAny filePaths[1..]

module.exports = {
  mtime
  existsAny
}
