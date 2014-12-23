express    = require 'express'
bodyParser = require 'body-parser'
Promise    = require 'bluebird'
R          = require 'ramda'
fs         = require 'fs'

createBlock = require './create-block'

readDirP = Promise.promisify fs.readdir


module.exports = (directory) ->
  app = express()

  app.use bodyParser.urlencoded(extended: false)

  app.set 'json spaces', 2

  app.get '/libraries', (req, res) ->
    readDirP(directory).then(R.pPipe(
      R.filter(R.match /blocks\.(\w+)/),
      R.map(R.replace('blocks.', '')),
      R.map(R.createMapEntry 'name')))
    .then (libs) ->
      res.json libs

  app.post '/libraries', (req, res) ->

  app.get '/libraries/:lib', (req, res) ->

  app.get '/libraries/:lib/blocks', (req, res) ->
  app.post '/libraries/:lib/blocks', (req, res) ->
    {lib, block} = req.body
    createBlock lib, block, directory
      .then (data) ->
        res.json data
      .catch (err) ->
        console.error err
        res.status(500).json(error: err.message)

  app.get '/libraries/:lib/blocks/:block', (req, res) ->


  app
