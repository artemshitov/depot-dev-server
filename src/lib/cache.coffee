Promise = require 'bluebird'
R = require 'ramda'

File = require './file'

class Cache
  constructor: ->
    @files = {}

  has: (requestPath) ->
    @files[requestPath]?

  get: (requestPath) ->
    @files[requestPath]

  update: (requestPath, entry) ->
    @files[requestPath] = entry
    this

class Entry
  constructor: (@content, @files) ->

  isValid: ->
    Promise.map @files, ({mtime, path}) ->
      R.pPipe(File.mtime, R.eq(mtime))(path)
    .then R.every R.I
    .catch (err) ->
      if err.cause.code == 'ENOENT' then false
      else throw err

Cache.Entry = Entry
module.exports = Cache
