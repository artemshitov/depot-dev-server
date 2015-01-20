fs = require 'fs'
Promise = require 'bluebird'
R = require 'ramda'

fsStat = Promise.promisify fs.stat

mtime = R.pPipe fsStat, R.prop('mtime'), R.func('getTime')

exists = (filePath) ->
  new Promise (resolve, reject) ->
    fs.exists filePath, resolve

existsAny = (filePaths) ->
  if filePaths.length == 0
    Promise.resolve undefined
  else
    exists(filePaths[0]).then (ex) ->
      if ex then filePaths[0]
      else existsAny filePaths[1..]

module.exports = {
  mtime
  exists
  existsAny
}
