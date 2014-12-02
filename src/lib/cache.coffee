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
  constructor: (@mime, @content, @files) ->

  isValid: ->
    Promise.map @files, ({ctime, path}) ->
      R.pPipe(File.ctime, R.eq(ctime))(path)
    .then R.every R.I

Cache.Entry = Entry
module.exports = Cache
