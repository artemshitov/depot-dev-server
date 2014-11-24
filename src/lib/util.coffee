findFirst = (pred, xs) ->
  if xs.length == 0
    undefined
  else if pred xs[0]
    xs[0]
  else
    findFirst pred, xs[1..]

any = (pred, xs) ->
  xs.reduce ((acc, x) -> pred(x) || acc), false

id = (x) -> x

flatten = (xs) -> [].concat.apply([], xs)

flatMap = (f, xs) -> flatten xs.map(f)

module.exports = {
  any
  id
  flatten
  flatMap
  findFirst
}
