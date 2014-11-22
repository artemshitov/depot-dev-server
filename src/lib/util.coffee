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
}
