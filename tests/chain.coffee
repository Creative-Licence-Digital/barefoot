assert = require 'assert'
bf     = require '../barefoot'

double = (x, done) -> done null, x * 2

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

	describe 'runChain', ->
		it 'should return 10', ->
			check = (res, done) ->
				assert.equal 10, res

			bf.runChain [
				bf.pure 5
				double
				check
			]
