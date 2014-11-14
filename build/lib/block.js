var Block, BlockFile, Library, path;

path = require('path');

Library = (function() {
  function Library(name) {
    this.name = name;
  }

  return Library;

})();

Block = (function() {
  function Block(library, name, version) {
    this.library = library;
    this.name = name;
    this.version = version;
  }

  Block.prototype.libraryName = function() {
    return this.library.name;
  };

  return Block;

})();

BlockFile = (function() {
  function BlockFile(block, platform, extension) {
    this.block = block;
    this.platform = platform;
    this.extension = extension;
  }

  BlockFile.fromPath = function(p) {
    var blockName, extension, fileName, fileNameParts, libName, platform, version, _ref, _ref1;
    _ref = p.split(path.sep).slice(-4), libName = _ref[0], blockName = _ref[1], version = _ref[2], fileName = _ref[3];
    fileNameParts = fileName.split('.');
    _ref1 = fileNameParts.length === 3 ? fileNameParts.slice(-2) : ['', fileNameParts[1]], platform = _ref1[0], extension = _ref1[1];
    return new BlockFile(new Block(new Library(libName.split('.')[1]), blockName, version), platform, extension);
  };

  BlockFile.prototype.changePlatform = function(platform) {
    return new BlockFile(this.block, platform, this.extension);
  };

  BlockFile.prototype.changeExtension = function(extension) {
    return new BlockFile(this.block, this.platform, extension);
  };

  BlockFile.prototype.toPath = function() {
    return path.join('blocks.' + this.block.libraryName(), this.block.name, this.block.version, this.platform === '' ? this.block.name + '.' + this.extension : [this.block.name, this.platform, this.extension].join('.'));
  };

  return BlockFile;

})();

module.exports = {
  Library: Library,
  Block: Block,
  BlockFile: BlockFile
};
