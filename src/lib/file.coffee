fs = require 'fs'
Promise = require 'bluebird'
R = require 'ramda'

fsExists = require './fs-exists'

fsStat = Promise.promisify fs.stat

ctime = R.pPipe fsStat, R.prop('ctime'), R.func('getTime')

existsAny = (filePaths) ->
  if filePaths.length == 0
    Promise.resolve undefined
  else
    fsExists(filePaths[0]).then (exists) ->
      if exists then filePaths[0]
      else existsAny filePaths[1..]

module.exports = {
  ctime
  existsAny
}
