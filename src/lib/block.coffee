path = require 'path'

class Library
  constructor: (@name) ->

class Block
  constructor: (@library, @name, @version) ->
  libraryName: -> @library.name

class BlockFile
  constructor: (@block, @platform, @extension) ->
  @fromPath: (p) ->
    [libName, blockName, version, fileName] = p.split(path.sep)[-4..]
    fileNameParts = fileName.split '.'
    [platform, extension] =
      if fileNameParts.length == 3 then fileNameParts[-2..]
      else ['', fileNameParts[1]]
    new BlockFile(
      new Block(new Library(libName.split('.')[1]), blockName, version),
      platform, extension)

  changePlatform: (platform) ->
    new BlockFile(@block, platform, @extension)

  changeExtension: (extension) ->
    new BlockFile(@block, @platform, extension)

  toPath: ->
    path.join 'blocks.' + @block.libraryName(),
      @block.name,
      @block.version,
      if @platform == ''
        @block.name + '.' + @extension
      else
        [@block.name, @platform, @extension].join '.'

module.exports = {
  Library,
  Block,
  BlockFile
}
