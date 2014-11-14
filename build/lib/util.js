var any, findFirst, flatMap, flatten, id;

findFirst = function(pred, xs) {
  if (xs.length === 0) {
    return void 0;
  } else if (pred(xs[0])) {
    return xs[0];
  } else {
    return findFirst(pred, xs.slice(1));
  }
};

any = function(pred, xs) {
  return xs.reduce((function(acc, x) {
    return pred(x) || acc;
  }), false);
};

id = function(x) {
  return x;
};

flatten = function(xs) {
  return [].concat.apply([], xs);
};

flatMap = function(f, xs) {
  return flatten(xs.map(f));
};

module.exports = {
  findFirst: findFirst,
  any: any,
  id: id,
  flatten: flatten,
  flatMap: flatMap
};
