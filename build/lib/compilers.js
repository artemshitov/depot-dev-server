var Block, Compiler, File, Promise, browserify, coffeeify, collect, fs, js, less, lessc, mdeps, path, readFile;

fs = require('fs');

path = require('path');

lessc = require('less');

browserify = require('browserify');

Promise = require('bluebird');

mdeps = require('module-deps');

collect = require('collect-stream');

coffeeify = require('coffeeify');

Block = require('./block');

File = require('./file');

readFile = Promise.promisify(fs.readFile);

Compiler = (function() {
  function Compiler(compileFn, depsFn) {
    this.compileFn = compileFn;
    this.depsFn = depsFn;
  }

  Compiler.prototype.run = function() {
    return Promise.all([
      this.compileFn.apply(this, arguments), this.depsFn.apply(this, arguments).then(function(deps) {
        return Promise.map(deps, function(dep) {
          return File.ctime(dep).then(function(ctime) {
            return {
              path: dep,
              ctime: ctime
            };
          });
        });
      })
    ]).then(function(_arg) {
      var deps, result;
      result = _arg[0], deps = _arg[1];
      return {
        content: result,
        dependencies: deps
      };
    });
  };

  return Compiler;

})();

less = (function() {
  var lessCompile, lessDependencies, lessOptions;
  lessOptions = function(platform, filePath) {
    return {
      paths: [path.join(process.cwd(), 'const', platform), path.dirname(filePath)],
      filename: filePath
    };
  };
  lessCompile = function(platform, filePath) {
    return readFile(filePath, {
      encoding: 'utf-8'
    }).then(function(data) {
      return Promise.promisify(lessc.render)(data, lessOptions(platform, filePath));
    });
  };
  lessDependencies = function(platform, filePath) {
    var parser;
    parser = new lessc.Parser(lessOptions(platform, filePath));
    return readFile(filePath, {
      encoding: 'utf-8'
    }).then(function(data) {
      return Promise.promisify(parser.parse, parser)(data);
    }).then(function(tree) {
      return Object.keys(parser.imports.files).concat([filePath]);
    });
  };
  return new Compiler(lessCompile, lessDependencies);
})();

js = (function() {
  var jsCompile, jsDependencies;
  jsCompile = function(platform, filePath) {
    return new Promise(function(resolve, reject) {
      return browserify().transform(coffeeify).add(filePath).bundle(function(err, data) {
        if (err != null) {
          return reject(err);
        } else {
          return resolve(data.toString('utf-8'));
        }
      });
    });
  };
  jsDependencies = function(platform, filePath) {
    var md;
    md = mdeps();
    md.end(filePath);
    return Promise.promisify(collect)(md).then(function(deps) {
      return deps.map(function(x) {
        return x.file;
      });
    });
  };
  return new Compiler(jsCompile, jsDependencies);
})();

module.exports = {
  less: less,
  js: js
};
