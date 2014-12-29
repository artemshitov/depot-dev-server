fs         = require 'fs'
path       = require 'path'

express    = require 'express'
bodyParser = require 'body-parser'
Promise    = require 'bluebird'
R          = require 'ramda'

createBlock = require './create-block'

readDirP  = Promise.promisify fs.readdir
readFileP = Promise.promisify fs.readFile
statP     = Promise.promisify fs.stat

readJSON = R.pPipe(
  readFileP,
  JSON.parse
)

startsWith = (pattern) -> (str) ->
  str.indexOf(pattern) == 0

endsWith = (pattern) -> (str) ->
  str.lastIndexOf(pattern) == str.length - pattern.length

isDirectory = (baseDir) -> (dirName) ->
  dir = path.resolve baseDir, dirName
  statP(dir).then (stat) ->
    stat.isDirectory()

listDirs = (dir) ->
  readDirP(dir).filter(isDirectory dir)

listVisibleDirs = R.pPipe(
  listDirs,
  R.reject(startsWith '.')
)


module.exports = (directory) ->
  app = express()

  app.use bodyParser.urlencoded(extended: false)

  app.set 'json spaces', 2

  app.get '/libraries', (req, res) ->
    listDirs(directory).then(R.pPipe(
      R.filter(R.match /blocks\.(\w+)/),
      R.map(R.replace('blocks.', '')),
      R.map(R.createMapEntry 'name')))
    .map((lib) ->
      readJSON(path.resolve(directory, 'blocks.' + lib.name, '.deps/descr.json'))
        .then (descr) ->
          R.assoc('current', descr.current)(R.assoc('description', descr.name, lib))
    )
    .then (libs) ->
      res.json libs

  app.post '/libraries', (req, res) ->

  app.get '/libraries/:lib', (req, res) ->
    libDir    = path.resolve(directory, "blocks.#{req.params.lib}")
    depsDir   = path.resolve(libDir, '.deps')
    descrPath = path.resolve(depsDir, 'descr.json')

    descrPromise = readJSON(descrPath)

    blocksPromise = readDirP(depsDir)
      .then(R.pPipe(
        R.filter(endsWith('.json')),
        R.filter(startsWith(req.params.lib))
      )).map (filename) ->
        readJSON(path.resolve(depsDir, filename)).then R.pPipe(
          R.omit(['name', 'version']),
          R.assoc('version', filename.split('-')[-1..][0].split('.')[..-2].join('.'))
        )

    Promise.all([descrPromise, blocksPromise])
      .then ([descr, files]) ->
        res.json R.mixin(descr, description: descr.name, name: req.params.lib, dependencies: files)


  app.get '/libraries/:lib/blocks', (req, res) ->
    libDir = path.resolve(directory, "blocks.#{req.params.lib}")

    listVisibleDirs(libDir)
      .map(R.createMapEntry 'name')
      .then (blocks) ->
        res.json blocks


  app.post '/libraries/:lib/blocks', (req, res) ->
    {lib, block} = req.body
    createBlock lib, block, directory
      .then (data) ->
        res.status(201).json(data)
      .catch (err) ->
        console.error err
        res.status(500).json(error: err.message)


  app.get '/libraries/:lib/blocks/:block', (req, res) ->
    blockDir = path.resolve('blocks.' + req.params.lib, req.params.block)
    listDirs(blockDir)
      .then (versions) ->
        res.json
          library: req.params.lib
          name: req.params.block
          versions: versions

  app
