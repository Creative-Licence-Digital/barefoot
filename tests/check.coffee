assert = require 'assert'
bf     = require '../barefoot'

schema =
  _a: Number
  _b: Boolean
  _c: String
  _d: /^[0-5]+$/
  _e: (v) -> v < 50
  _f: ['dick', 'jane']
  _g:
    a: Number
    b: String
  h: 1
  _i: [String]

describe 'bf', ->
  describe 'check', ->

    it 'should validate all fields', ->
      obj =
        a: 2
        b: true
        c: 'hey'
        d: '42'
        e: 24
        f: 'dick'
        g:
          a: 2
          b: 'hi'
        h: 'sup?'
        i: ['hey', 'there']

      res = bf.check obj, schema
      assert.equal res.ok, true

    it 'should not require optional fields', ->
      obj =
        h: 'sup?'

      res = bf.check obj, schema
      assert.equal res.ok, true

    it 'should validate numbers', ->
      obj =
        a: 'hi'
        h: 'sup?'

      res = bf.check obj, schema
      assert.equal res.ok, false

    it 'should validate booleans', ->
      obj =
        b: 'hi'
        h: 'sup?'

      res = bf.check obj, schema
      assert.equal res.ok, false

    it 'should validate strings', ->
      obj =
        c: 2
        h: 'sup?'

      res = bf.check obj, schema
      assert.equal res.ok, false

    it 'should validate regexps', ->
      obj =
        d: '92'
        h: 'sup?'

      res = bf.check obj, schema
      assert.equal res.ok, false

    it 'should use validation functions', ->
      obj =
        e: 90
        h: 'sup?'

      res = bf.check obj, schema
      assert.equal res.ok, false

    it 'should validate enums', ->
      obj =
        f: 'bob'
        h: 'sup?'

      res = bf.check obj, schema
      assert.equal res.ok, false

    it 'should validate typed arrays', ->
      obj =
        f: 'bob'
        i: [2, 'hey']

      res = bf.check obj, schema
      assert.equal res.ok, false
