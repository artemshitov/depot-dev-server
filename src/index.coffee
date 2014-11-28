path      = require 'path'

express   = require 'express'
Promise   = require 'bluebird'
R         = require 'ramda'

Block     = require './lib/block'
Compilers = require './lib/compilers'
File      = require './lib/file'


run = (directory = process.cwd(), port = process.env.PORT || 3030) ->
  app = express()
  cache = {}

  app.get '/.build/blocks.*/*/*/*', (req, res) ->
    recompile = ->
      extensions =
        css: ['less']
        js: ['coffee', 'js']

      extCompilers =
        coffee: 'js'
        js: 'js'
        less: 'less'

      blockFile = Block.BlockFile.fromPath(req.path)

      filePaths = R.compose(R.flatten, R.map) (ext) ->
        [
          path.join(directory, blockFile.changeExtension(ext).toPath())
          path.join(directory, blockFile.changeExtension(ext).changePlatform('').toPath())
        ]
      , extensions[blockFile.extension]

      File.existsAny filePaths
        .then (filePath) ->
          compiler = extCompilers[path.extname(filePath)[1..]]
          type = blockFile.extension
          Compilers[compiler].run(blockFile.platform, filePath)
            .then (result) ->
              cache[req.path] = R.mixin result, {type}
              res.type(type).send result.content
            .catch (err) ->
              console.error err
              res.status(500).send('Error: ' + err.message)
        .catch (err) ->
          console.log err
          res.status(404).end()

    cacheEntry = cache[req.path]
    if cacheEntry?
      Promise.map cacheEntry.dependencies, (dep) ->
        File.ctime dep.path
          .then (ctime) ->
            ctime > dep.ctime
      .then (results) ->
        if R.some R.identity, results
          recompile()
        else
          res.type(cacheEntry.type).send(cacheEntry.content)
    else
      recompile()

  app.use express.static(directory)

  app.listen port
  console.log "Listening on port #{port}"

module.exports = {
  run
}
