assert = require 'assert'
bf     = require '../barefoot'


multBy = (i) -> 
  (x, done) -> done null, x * i

double = multBy(2)
triple = multBy(3)

describe 'barefoot', ->
	describe 'chain', ->


		it 'should return 32', ->
			fn = bf.chain [
				double
				double
				bf.chain [
					double
					double
					double
				]
			]

			fn 1, (err, res) ->
				assert.equal 32, res
				assert.equal err, null
 

  describe 'parallel', -> 
    
    it 'should return an array whom total is 5', -> 
      fn = bf.parallel [
        double
        triple
      ]

      fn 1, (err, res) -> 
        assert.equal 5, res.reduce ((a, b) -> a + b), 0
        

  describe 'amap', -> 
    
    it 'should apply a bfunc method to an array of values', ->
    
      fn = bf.amap double

      fn [1, 2, 3, 4], (err, res) -> 
        assert.equal 20, res.reduce ((a, b) -> a + b), 0


  describe 'avoid', ->

    it 'should turn a "void" synchronous func into a bfunc', ->
     
      val = 0
      fn = bf.avoid(() -> val += 1)

      fn null, (err, res) -> 
        assert.equal 1, val

      
  describe 'select', ->

    it 'should turn a synchronous func into a bfunc', ->
     
      fn = bf.select((i) -> i + 1)

      fn 1, (err, res) -> 
        assert.equal 2, res


  describe 'into', ->
    
    it 'should execute a bfunc and stores the result in a given param', ->
    
      fn = bf.into("double", double)
      fn 1, (err, res) -> 
        assert.equal 2, res.double

    
