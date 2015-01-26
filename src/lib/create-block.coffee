path    = require 'path'

vfs     = require 'vinyl-fs'
through = require 'through'
_       = require 'underscore'
R       = require 'ramda'
Promise = require 'bluebird'

File = require './file'

createBlock = (dir, blockConfig) ->
  new Promise (resolve, reject) ->
    # Check if the block already exists
    File.exists path.resolve(dir, 'blocks.' + blockConfig.lib, blockConfig.block)
      .then (exists) ->
        if exists
          reject new Error('This block already exists')
        else
          stream = vfs.src path.resolve(__dirname, '../templates/block/**/*.*')
          stream.pipe through (_file) ->
            file = _file.clone()
            file.path = _.template(file.path)(blockConfig)

            # If file has textual contents
            textuals = ['.js', '.less', '.svg', '.html', '.yaml', '.md']
            if R.contains path.extname(file.path), textuals
              source = file.contents.toString 'utf8'
              file.contents = new Buffer _.template(source)(blockConfig)

            @queue(file)
          .pipe vfs.dest(dir)

          stream.on 'error', reject
          stream.on 'end', -> resolve blockConfig

module.exports = createBlock
