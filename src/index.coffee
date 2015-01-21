path      = require 'path'

express   = require 'express'
Promise   = require 'bluebird'
R         = require 'ramda'

mime      = require './lib/mime'
api       = require './lib/api'

Block     = require './lib/block'
Compilers = require './lib/compilers'
File      = require './lib/file'
Cache     = require './lib/cache'


createServer = (directory) ->
  app = express()
  cache = new Cache()
  apiApp = api(directory)

  app.use '/api/beta', apiApp

  app.get '/.build/blocks.*/*/*/*', (req, res) ->
    extensions =
      css: ['less']
      js: ['coffee', 'js']

    extCompilers =
      coffee: 'js'
      js: 'js'
      less: 'less'

    recompile = ->
      blockFile = Block.BlockFile.fromPath(req.path)

      filePaths = R.compose(R.flatten, R.map) (ext) ->
        [
          path.join(directory, blockFile.changeExtension(ext).toPath())
          path.join(directory, blockFile.changeExtension(ext).changePlatform('').toPath())
        ]
      , extensions[blockFile.extension]

      compileFile = (filePath) ->
        compiler = extCompilers[path.extname(filePath)[1..]]
        Compilers[compiler].run(blockFile.platform, filePath)
          .then ({content, files}) ->
            cache.update(req.path, new Cache.Entry(content, files))
            res.type(mime(req.path)).send content
          .catch (err) ->
            console.error err
            res.status(500).send('Error: ' + err.message)

      File.withFirstExistent(compileFile)(filePaths)
        .catch (err) ->
          console.log err
          res.status(404).send(err.message)

    if cache.has(req.path)
      cacheEntry = cache.get(req.path)
      cacheEntry.isValid().then (valid) ->
        if valid
          res.type(mime(req.path)).send(cacheEntry.content)
        else
          recompile()
    else
      recompile()

  app.use express.static(directory)
  app

module.exports = {
  createServer
}
