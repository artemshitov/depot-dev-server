path    = require 'path'

vfs     = require 'vinyl-fs'
through = require 'through'
_       = require 'underscore'
R       = require 'ramda'
Promise = require 'bluebird'

fsExists = require './fs-exists'

createBlock = (lib, block, dir) ->
  new Promise (resolve, reject) ->
    # Check if the block already exists
    fsExists path.resolve(dir, 'blocks.' + lib, block)
      .then (exists) ->
        if exists
          reject new Error('This block already exists')
        else
          stream = vfs.src path.resolve(__dirname, '../templates/block/**/*.*')
          stream.pipe through (_file) ->
            file = _file.clone()
            file.path = _.template(file.path)({lib, block})

            # If file has textual contents
            textuals = ['.js', '.less', '.svg', '.html']
            if R.contains path.extname(file.path), textuals
              source = file.contents.toString 'utf8'
              file.contents = new Buffer _.template(source)({lib, block})

            @queue(file)
          .pipe vfs.dest(dir)

          stream.on 'error', (err) -> reject err
          stream.on 'end', -> resolve {lib, block}

module.exports = createBlock
