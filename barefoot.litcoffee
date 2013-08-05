barefoot
========

**barefoot** is a library that assists with creating large asynchronous
JavaScript web applications through the use of "barefoot functions", or
*bfunctions*.

Specifically, the library provides a bunch of useful bfunctions and convenience
methods that produce bfunctions.

To install it

`npm install barefoot`

To use it

`bf = require 'barefoot'`
   
Module dependencies
-------------------

    lateral = require 'lateral'
    _       = require 'underscore'

Error wrapper
-------------

### errorWrapper

    errorWrapper = (handler) ->
      (func) ->
        (err, args...) ->
          if err?
            handler err
          else
            func args...

### swap

Create a function of form (b, a, c...) from a function of form (a, b, c...).

    swap = (func) ->
      (b, a, c...) ->
        func a, b, c...
  
Control flow bfunction builders
-------------------------------

Useful methods that create bfunctions.

### chain

    chain = (source) ->
      (params, done) ->

        bfuncs = if _.isFunction source then source() else source

        if bfuncs.length == 0
          done null, params
        else
          bfuncs[0] params, (err, res) ->
            if err?
              done err, res
            else
              chain(funcs[1..])(res, done)

### parallel

    parallel = (source) ->
      (params, done) -> 

        bfuncs = if _.isFunction source then source() else source
        
        i = 0
        errors = []
        results = []
        tempDone = (err, result) ->
          i++
          errors.push(err) if err?
          results.push result
          if i == bfuncs.length
            error = if errors.length > 0  then errors else null
            done error, results

        bfuncs.forEach (func) ->
          func params, tempDone

### amap

    amap = (func, nbProcesses = 1) ->
      (array, done) ->
        results = []
        errors = null
        unit = lateral.create (complete, item) ->
          func item, (err, res) ->
            if err?
              errors ?= []
              errors.push(err)
              results.push null
            else
              results.push res
            complete()
        , nbProcesses

        unit.add(array).when () ->
          done(errors, results) if done?

### sequence

    # todo: return a bfunction?
    sequence = (done) ->
      queue = []
      running = false
      finished = false
      result = null

      run = ->
        running = true

        if queue.length > 0
          func = queue[0]
          queue = queue[1..]

          func result, (err, res) ->
            if err?
              done err
            else
              result = res
              run()
        else
          running = false
          if finished
            done null, result

      add: (func) ->
        queue.push func
        if not running then run()

      then: (func) ->
        queue.push swap func
        if not running then run()

      end: ->
        finished = true
        if not running then run()

      w: errorWrapper done


General bfunction builders
--------------------------

### avoid

    avoid = (func) ->
      (params, done) ->
        func(params)
        done null, params 

### select

    select = (func) ->
      (params, done) ->
        done null, func(params)

Object bfunction builders
-------------------------

### get

    get = (property) ->
      select (params) -> params[property]

Array bfunction builders
------------------------

### map

    map = (func) ->
      select (list) -> list.map(func)

### reduce

    reduce = (func) ->
      select (list) -> list.reduce(func)

Standard bfunctions
-------------------

### identity

    identity = (params, done) ->
      done null, params

Web bfunctions
--------------

### HttpResponse

    class HttpResponse
      code: 200
      data: null
      headers: null
      type: null
      location: null
      template: null

      constructor: (params) ->
        if _.isFunction params
          @apply = params
        else
          {@code, @data, @headers, @type, @location} = params

      apply: (res) ->
        for key, value of @headers
          res.set key, value

        if @type?
          res.type @type

        if @location?
          res.location @location

        if @template?
          res.render @template, @data
        else
          res.send @code, @data

### getRequestParams

    getRequestParams = (req) ->

      params = {}

      for field in ['body', 'query', 'params']
        params = _.extend params, req[field]

      for field in ['body', 'query', 'params', 'files', 'headers', 'cookies',
        'path', 'host', 'protocol', 'secure', 'originalUrl', 'user']

        if not field of params and req[field]?
          Object.defineProperty params, field,
            enumerable: false
            configurable: true
            writable: true
            value: req[field]

      params

### redirect

    redirect = (location) ->
      new HttpResponse code: 302, location: location

### notFound

    notFound = ->
      new HttpResponse code: 404

### webService

    webService = (method) ->
      (req, res) ->

        method getRequestParams(req), (err, data) ->

          if err?
            if err instanceof HttpResponse
              err.apply res
            else
              console.error err
              res.send 500
          else
            response =
              if data instanceof HttpResponse
                data
              else if data?
                new HttpResponse code: 200, data: data
              else
                new HttpResponse code: 404

            response.apply res

### webPage

    webPage = (template, method) ->
      (req, res) ->

        if not method? and template?
          data = getRequestParams(req)
          data.__ =
            template: template
          res.render template, data
        else
          method getRequestParams(req), (err, data) ->

            if err?
              if err instanceof HttpResponse
                err.apply res
              else
                console.error err
                res.send 500
            else
              response =
                if data instanceof HttpResponse
                  data
                else if data?
                  new HttpResponse code: 200, data: data
                else
                  new HttpResponse {template, data}

### middleware

    middleware = (func) ->
      (req, res, ok) ->
        func getRequestParams(req), (err, val) ->
          if err?
            if err instanceof HttpResponse
              err.apply res
            else
              console.error err
              res.send 500
          else
            ok()

### memoize
    
    memoize = (method, seconds) ->
      cache = {}

      (params, done) ->
        hash = JSON.stringify(params)
        if cache[hash]? and cache[hash].expiration > new Date()
          done null, cache[hash].result
        else
          method params, (err, res) ->
            if not err?
              cache[hash] =
                result : res
                expiration : (new Date()).setSeconds((new Date()).getSeconds() + seconds)

            done err, res

Export public methods
---------------------

    module.exports = {
      errorWrapper
      swap
      chain
      parallel
      amap
      sequence
      avoid
      select
      get
      map
      reduce
      identity
      HttpResponse
      redirect
      notFound
      webService
      webPage
      middleware
      memoize
    }
