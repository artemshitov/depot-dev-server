express    = require 'express'
bodyParser = require 'body-parser'
R          = require 'ramda'

createBlock = require './create-block'

module.exports = (directory) ->
  app = express()

  app.use bodyParser.urlencoded(extended: false)

  app.post '/blocks', (req, res) ->
    {lib, block} = req.body
    createBlock lib, block, directory
      .then (data) ->
        res.json data
      .catch (err) ->
        console.error err
        res.status(500).json(error: err.message)

  app
