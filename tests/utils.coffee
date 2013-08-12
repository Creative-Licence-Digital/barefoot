
multBy = (i) -> 
  (x, done) -> done null, x * i

double = multBy(2)
triple = multBy(3)


module.exports = {
  double
  triple
}
