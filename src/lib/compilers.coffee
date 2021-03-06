fs = require 'fs'
path = require 'path'
lessc = require 'less'
browserify = require 'browserify'
Promise = require 'bluebird'
through = require 'through'
R = require 'ramda'
autoprefixer = require 'autoprefixer-core'
postcss = require 'postcss'

Block = require './block'
File = require './file'

readFile = Promise.promisify fs.readFile

substitute = (sub) -> (str) ->
    if sub?
        regexp = new RegExp(sub.from, 'g')
        str.replace(regexp, sub.to)
    else
        str


class Compiler
    constructor: (@compileFn) ->
    run: ->
        @compileFn.apply(@, arguments).then (output) ->
            Promise.map output.files, (path) ->
                File.mtime(path).then (mtime) ->
                    path: path
                    mtime: mtime
            .then (files) ->
                content: output.content
                files: files

less = do ->
    lessRender = Promise.promisify(lessc.render)

    lessOptions = (platform, filePath) ->
        sourceMap:
            sourceMapFileInline: true
        paths: [
            # version directory
            path.dirname filePath

            # library config directory
            path.join(path.resolve(filePath, '../../../'), 'const', platform)

            # project config directory
            path.join(path.resolve(filePath, '../../../../'), 'const', platform)
        ]
        filename: filePath
        ieCompat: false

    lessCompile = (opts, filePath) ->
        readFile(filePath, encoding: 'utf-8').then(substitute(opts.substitute))
            .then (input) ->
                lessc.render(input, lessOptions(opts.platform, filePath))
            .then (out) ->
                postcss([autoprefixer]).process(out.css)
                    .then (result) ->
                        content: result.css
                        files: [filePath].concat(out.imports)

    new Compiler(lessCompile)


js = do ->
    transformer = (f) -> () ->
        buffer = ''
        write = (data) -> buffer += data
        end = ->
            @queue f(buffer)
            @queue null
        through write, end

    imagePaths = (filePath) -> transformer (js) ->
        blockPath = path.resolve(filePath, '../../../..')
        relPath = path.relative(blockPath, path.resolve(filePath, '..'))
        js.replace /(['"])url\((?!\/)([^'"]+)\)/g, "$1url(/#{relPath}/$2)"

    jsCompile = (opts, filePath) ->
        files = []
        new Promise (resolve, reject) ->
            browserify(debug: true) # source maps enabled
                .transform(transformer(substitute(opts.substitute)))
                .transform(imagePaths(filePath))
                .add(filePath)
                .on 'file', (file) ->
                    files.push(file)
                .bundle (err, data) ->
                    if err? then reject err
                    else
                        resolve
                            content: data.toString('utf-8')
                            files: files

    new Compiler(jsCompile)


module.exports = {
    less
    js
}
