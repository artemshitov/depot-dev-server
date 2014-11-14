var Promise, ctime, existsAlternative, fs, fsExists, util;

fs = require('fs');

Promise = require('bluebird');

util = require('./util');

fsExists = Promise.promisify(require('fs-exists'));

ctime = function(filePath) {
  return Promise.promisify(fs.stat)(filePath).then(function(stats) {
    return stats.ctime.getTime();
  });
};

existsAlternative = function(filePaths) {
  return Promise.map(filePaths, function(filePath) {
    return fsExists(filePath).then(function(exists) {
      return [filePath, exists];
    });
  }).then(function(results) {
    return util.findFirst((function(_arg) {
      var exists, filePath;
      filePath = _arg[0], exists = _arg[1];
      return exists;
    }), results);
  }).then(function(result) {
    if (result != null) {
      return result[0];
    } else {
      return void 0;
    }
  });
};

module.exports = {
  ctime: ctime,
  existsAlternative: existsAlternative
};
