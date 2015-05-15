path      = require 'path'

express   = require 'express'
Promise   = require 'bluebird'
R         = require 'ramda'

mime      = require './lib/mime'
api       = require './lib/api'

compilers = require './lib/compilers'
Block     = require './lib/block'
File      = require './lib/file'
Cache     = require './lib/cache'


# Compile a file
#
# # Options
# - platform: String (required)
# - substitute: { from: String|RegExp, to: String } (optional)
#
# Returns Promise[{content: String, files: Array[String]}]
compileFile = (opts, filePath) ->
    compiler = switch path.extname(filePath)
        when '.less' then compilers.less
        when '.css' then compilers.css
        when '.js' then compilers.js
    compiler.run(opts, filePath)

filesToCompile = (directory, blockFile) ->
    extensions =
        css: ['less']
        js: ['js']

    platforms = R.mapAccum(((acc, x) -> [acc.concat([x]), acc.concat([x])]),
        [], blockFile.platform.split('-'))[1]
            .map(R.join('-'))
            .reverse()
            .concat([''])

    R.flip(R.chain) extensions[blockFile.extension], (ext) ->
        withExt = blockFile.changeExtension(ext)
        platforms.map (p) ->
            path.join(directory, withExt.changePlatform(p).toPath())

redirectFromBuild = (req, res) ->
    res.redirect('/' + req.path.split('/')[2..].join('/'))

renderBlock = (directory, cache) -> (req, res) ->
        # Substitution feature
        #
        # The server may substitute strings in the source file prior to compilation
        # if query parameter `substitute` is present. It is useful for experimenting with
        # global design constants
        # Format: ...?substitute=/0.1.0/0.2.0/
        if req.query.substitute?
            [from, to] = req.query.substitute[1...-1].split('/')
            substitute = {from, to}

        recompile = ->
            blockFile = Block.BlockFile.fromPath(req.path)
            filePaths = filesToCompile(directory, blockFile)

            opts =
                platform: blockFile.platform
                substitute: substitute

            File.withFirstExistent(R.partial(compileFile, opts))(filePaths)
                .then ({content, files}) ->
                    cache.update(req.originalUrl, new Cache.Entry(content, files))
                    res.type(mime(req.path)).send content
                .catch (err) ->
                    console.error err
                    res.status(500).send('Error: ' + err.message)

        if cache.has(req.originalUrl)
            cacheEntry = cache.get(req.originalUrl)
            cacheEntry.isValid().then (valid) ->
                if valid
                    res.type(mime(req.path)).send(cacheEntry.content)
                else
                    recompile()
        else
            recompile()


createServer = (directory) ->
    app = express()
    app.use '/api/beta', api(directory)

    cache = new Cache()

    app.get '/.build/blocks.*/*/*/*.(js|css)', renderBlock(directory, cache)

    # This is made for relative paths in CSS to work
    app.get '/.build/*', redirectFromBuild

    app.use express.static(directory)
    app


module.exports = {
    createServer
}
