fs         = require 'fs'
path       = require 'path'
lessc      = require 'less'
browserify = require 'browserify'
Promise    = require 'bluebird'
mdeps      = require 'module-deps'
collect    = require 'collect-stream'
coffeeify  = require 'coffeeify'
through    = require 'through'

Block = require './block'
File  = require './file'

readFile = Promise.promisify fs.readFile

class Compiler
  constructor: (@compileFn, @depsFn) ->
  run: ->
    Promise.all([
      @compileFn.apply(this, arguments),
      @depsFn.apply(this, arguments).then (deps) ->
        Promise.map deps, (dep) ->
          File.ctime(dep).then (ctime) ->
            path: dep
            ctime:    ctime
    ]).then ([result, deps]) ->
      content: result
      dependencies: deps

less = do ->
  lessOptions = (platform, filePath) ->
    paths: [
      path.join(path.resolve(filePath, '../../../../'), 'const', platform)
      path.dirname filePath
    ]
    filename: filePath

  lessCompile = (platform, filePath) ->
    readFile filePath, encoding: 'utf-8'
      .then (data) ->
        Promise.promisify(lessc.render)(data, lessOptions(platform, filePath))

  lessDependencies = (platform, filePath) ->
    parser = new lessc.Parser(lessOptions(platform, filePath))
    readFile filePath, encoding: 'utf-8'
      .then (data) ->
        Promise.promisify(parser.parse, parser)(data)
      .then (tree) ->
        Object.keys(parser.imports.files).concat([filePath])

  new Compiler(lessCompile, lessDependencies)


js = do ->
  transformer = (f) -> () ->
    buffer = ''
    write  = (data) -> buffer += data
    end    = ->
      @queue f(buffer)
      @queue null
    through write, end

  include2require = transformer (js) ->
    js.replace /\/\/= include (.+)/g, 'require(\'./$1\');'

  imagePaths = (filePath) -> transformer (js) ->
    js.replace /(['"])url\((?!\/)([^'"]+)\)/g,
      "$1url(/#{path.relative(path.resolve(filePath, '../../../..'), path.resolve(filePath, '..'))}/$2)"

  jsCompile = (platform, filePath) ->
    new Promise (resolve, reject) ->
      browserify()
        .transform(coffeeify)
        .transform(include2require)
        .transform(imagePaths(filePath))
        .add(filePath).bundle (err, data) ->
          if err? then reject err
          else resolve data.toString 'utf-8'

  jsDependencies = (platform, filePath) ->
    md = mdeps(transform: [coffeeify, include2require])
    md.end filePath
    Promise.promisify(collect)(md)
      .then (deps) ->
        deps.map (x) -> x.file

  new Compiler(jsCompile, jsDependencies)


module.exports = {
  less
  js
}
