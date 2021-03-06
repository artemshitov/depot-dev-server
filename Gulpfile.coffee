gulp = require 'gulp'
coffee = require 'gulp-coffee'
chmod = require 'gulp-chmod'
mapStream = require 'map-stream'
del = require 'del'

gulp.task 'coffee', ->
  gulp.src ['src/**/*.coffee', '!src/bin/**/*.coffee']
    .pipe coffee bare: true
    .pipe gulp.dest 'build'

gulp.task 'templates', ->
  gulp.src ['src/templates/**/*.*']
    .pipe gulp.dest 'build/templates'

gulp.task 'bin', ->
  gulp.src 'src/bin/**/*.coffee'
    .pipe coffee bare: true
    .pipe mapStream (file, done) -> # add shebang
      file.contents =
        new Buffer '#!/usr/bin/env node\n\n' + file.contents.toString('utf8')
      done null, file
    .pipe chmod(755)
    .pipe gulp.dest 'build/bin'

gulp.task 'clean', ->
  del.sync ['build']

gulp.task 'build', ['coffee', 'bin', 'templates']

gulp.task 'prepublish', ['clean', 'build']

gulp.task 'watch', ['build'], ->
  gulp.watch 'src/**/*.*', ['build']
