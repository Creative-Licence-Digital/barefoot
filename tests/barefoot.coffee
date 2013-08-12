assert = require 'assert'
bf     = require '../barefoot'
testUtils = require './utils'


describe 'barefoot', ->
  describe 'errorWrapper', ->

    it 'should handle error', ->

      callback = (err, res) ->
        assert err is 'error'

      w = bf.errorWrapper callback
      
      giveError = (params, done) ->
        done 'error'

      giveError null, w (res) ->
        assert false

    it 'should not do anything to non-errors', ->

      callback = (err, res) ->
        assert false

      w = bf.errorWrapper callback

      testUtils.double 10, w (res) ->
        assert true

  describe 'swap', ->

    it 'should swap args', ->

      fn = (a, b, c, d) ->
        assert.equal a, 1
        assert.equal b, 2
        assert.equal c, 3
        assert.equal d, 4

      bf.swap(fn) 2, 1, 3, 4

	describe 'chain', ->


		it 'should return 32', ->
			fn = bf.chain [
				testUtils.double
				testUtils.double
				bf.chain [
					testUtils.double
					testUtils.double
					testUtils.double
				]
			]

			fn 1, (err, res) ->
				assert.equal 32, res
				assert.equal err, null
 

  describe 'parallel', -> 
    
    it 'should return an array whom total is 5', -> 
      fn = bf.parallel [
        testUtils.double
        testUtils.triple
      ]

      fn 1, (err, res) -> 
        assert.equal 5, res.reduce ((a, b) -> a + b), 0
        

  describe 'amap', -> 
    
    it 'should apply a bfunc method to an array of values', ->
    
      fn = bf.amap testUtils.double

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
    
      fn = bf.into("double", testUtils.double)
      fn 1, (err, res) -> 
        assert.equal 2, res.double

  describe 'get', ->

    it 'should get a param of an object', ->

      dog =
        name: 'Fido'
        age: 7
        address:
          street: 'The Corso'
          suburb: 'Manly'

      bf.get('age') dog, (err, res) ->
        assert.equal res, 7

  describe 'map', ->

    it 'should map a bfunct that returns a list', ->

      fn = (i) -> i * 2
      bfn = bf.map fn

      bfn [1, 2, 3, 4], (err, res) ->
        assert.equal res.reduce((a, b) -> a + b), 20

  describe 'reduce', ->

    it 'should reduce a bfunct that returns a list', ->

      fn = (a, b) -> a + b
      bfn = bf.reduce fn

      bfn [1, 2, 3, 4], (err, res) ->
        assert.equal res, 10

  describe 'identity', ->

    it 'should act as the identity function', ->

      bf.identity 12, (err, res) ->
        assert.equal res, 12
