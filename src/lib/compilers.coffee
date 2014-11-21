fs         = require 'fs'
path       = require 'path'
lessc      = require 'less'
browserify = require 'browserify'
Promise    = require 'bluebird'
mdeps      = require 'module-deps'
collect    = require 'collect-stream'
coffeeify  = require 'coffeeify'

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
  jsCompile = (platform, filePath) ->
    new Promise (resolve, reject) ->
      browserify().transform(coffeeify).add(filePath).bundle (err, data) ->
        if err? then reject err
        else resolve data.toString 'utf-8'

  jsDependencies = (platform, filePath) ->
    md = mdeps()
    md.end filePath
    Promise.promisify(collect)(md)
      .then (deps) ->
        deps.map (x) -> x.file

  new Compiler(jsCompile, jsDependencies)


module.exports = {
  less
  js
}
