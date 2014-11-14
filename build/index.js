var Block, Compilers, File, Fn, Promise, express, path, run, util;

path = require('path');

express = require('express');

Promise = require('bluebird');

Fn = require('fn.js');

Block = require('./lib/block');

Compilers = require('./lib/compilers');

File = require('./lib/file');

util = require('./lib/util');

run = function(directory, port) {
  var app, cache;
  if (directory == null) {
    directory = process.cwd();
  }
  if (port == null) {
    port = process.env.PORT || 3030;
  }
  app = express();
  app.use(express["static"](directory));
  cache = {};
  app.get('/.build/blocks.*/*/*/*', function(req, res) {
    var cacheEntry, recompile;
    recompile = function() {
      var blockFile, extCompilers, extensions, filePaths;
      extensions = {
        css: ['less'],
        js: ['coffee', 'js']
      };
      extCompilers = {
        coffee: 'js',
        js: 'js',
        less: 'less'
      };
      blockFile = Block.BlockFile.fromPath(req.path);
      filePaths = util.flatMap(function(ext) {
        return [path.join(directory, blockFile.changeExtension(ext).toPath()), path.join(directory, blockFile.changeExtension(ext).changePlatform('').toPath())];
      }, extensions[blockFile.extension]);
      console.log(filePaths);
      return File.existsAlternative(filePaths).then(function(filePath) {
        var compiler, type;
        if (filePath != null) {
          compiler = extCompilers[path.extname(filePath).slice(1)];
          type = blockFile.extension;
          return Compilers[compiler].run(blockFile.platform, filePath).then(function(result) {
            cache[req.path] = Fn.merge(result, {
              type: type
            });
            return res.type(type).send(result.content);
          })["catch"](function(err) {
            console.error(err);
            return res.status(500).send('Error: ' + err.message);
          });
        } else {
          return res.status(404).end();
        }
      });
    };
    cacheEntry = cache[req.path];
    if (cacheEntry != null) {
      return Promise.map(cacheEntry.dependencies, function(dep) {
        return File.ctime(dep.path).then(function(ctime) {
          return ctime > dep.ctime;
        });
      }).then(function(results) {
        if (util.any(util.id, results)) {
          return recompile();
        } else {
          return res.type(cacheEntry.type).send(cacheEntry.content);
        }
      });
    } else {
      return recompile();
    }
  });
  app.listen(port);
  return console.log("Listening on port " + port);
};

module.exports = {
  run: run
};
