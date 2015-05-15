fs = require 'fs'
Promise = require 'bluebird'
R = require 'ramda'

fsStat = Promise.promisify fs.stat

mtime = R.pipeP fsStat, R.prop('mtime'), R.invoke('getTime')

findP = (f) -> (xs) ->
  Promise
    .map(xs, f)
    .then R.zipWith((source, result) -> result && source)(xs)
    .then R.find(R.identity)

exists = (filePath) ->
  console.log(filePath)
  new Promise (resolve, reject) ->
    fs.exists filePath, resolve

withFirstExistent = (f) -> (filePaths) ->
  findP(exists)(filePaths)
    .then (result) ->
      if result? then f(result)
      else throw new Error('None of the paths tried exist:\n' + filePaths.join(',\n'))

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
  withFirstExistent
}
