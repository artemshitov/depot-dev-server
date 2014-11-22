path      = require 'path'

express   = require 'express'
Promise   = require 'bluebird'
Fn        = require 'fn.js'

Block     = require './lib/block'
Compilers = require './lib/compilers'
File      = require './lib/file'
util      = require './lib/util'


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

      filePaths = util.flatMap (ext) ->
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
              cache[req.path] = Fn.merge result, {type}
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
        if util.any util.id, results
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
