Barefoot
========

Barefoot is a utility-belt library for Node for asynchronous functions manipulation

To install it

`npm install barefoot`

To use it

`bf = require 'barefoot'`


Module dependencies
-------------------


    lateral = require 'lateral'
    _       = require 'underscore'



Let's get started
------------------


**error**

Barefoot error class used to construct consistently formatted error responses

    bfError = class BFError
      constructor: (errorCode, message, statusCode) ->
        @errorCode = errorCode
        @message = message
        @statusCode = parseInt(statusCode) ? 500

      sendRes: (res) ->
        res.json @statusCode, { error: { code: @errorCode, message: @message }  }


**toDictionary**

Transform an array of object into a dictionary based on the property passed as a second param

    toDictionary = (array, prop) ->
      dictionary = {}
      array.forEach (elt) ->
        dictionary[elt[prop]] = elt if elt? and elt[prop]?
      return dictionary



**has**

Provides a function which test if parameters object has certain properties

    has = (parameters) ->
      (params, done) ->
        ok = true
        ok = (ok and params? and params[par]?) for par in parameters
        done (if ok then null else new Error("Missing Parameters")), params


**amap**

Asynchronous map
Use the awesome **lateral** module to do the job

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

**chain**

Chain aynschronous methods with signature (val, done) -> done(err, result)
Stop if one of the method has an error in the callback

    chain = (funcs) ->
      (val, done) ->
        if funcs.length == 0
          done null, val
        else
          funcs[0] val, (err, res) =>
            if err?
              done err, res
            else
              chain(funcs[1..])(res, done)

**avoid**

Wrap a void returning function to make it callable in a chain

    avoid = (func) ->
      (params, done) ->
        func(params)
        done null, params


**nothing**

Do nothing but be defined

    nothing = (params, done) -> done null, params


**parallel**

Execute asynchronous functions which take same inputs

    parallel = (funcs) ->
      (params, done) ->

        i = 0
        errors = []
        results = []
        tempDone = (err, result) ->
          i++
          errors.push(err) if err?
          results.push result
          if i == funcs.length
            error = if errors.length > 0  then errors else null
            done error, results

        funcs.forEach (func) ->
          func params, tempDone


**getRequestParams**

    getRequestParams = (req) ->
      params = {}
      for field in ["body", "query", "params", "files"]
        if req[field]?
          params = _.extend params, req[field]
      params.user = req.user if req.user?
      params.flashdata = req.flashdata if req.flashdata?
      params.ip = req.headers['x-forwarded-for'] ? req.connection.remoteAddress ? req.socket.remoteAddress ? req.connection.socket.remoteAddress
      params



**webPagePost**

    webPagePost = (method, redirect) ->
      (req, res) ->
        method getRequestParams(req), (err, data) ->

          if err?
            return if (err instanceof BFError) then err.sendRes(res) else res.send 500

          data = {} if not data?
          data.user = req.user if req.user? and not data.user?
          req.flashdata = data.flashdata if data.flashdata?

          res.redirect redirect

**csv**

    csv = (method) ->
      (req, res) ->
        params = {}
        for field in ["body", "query", "params"]
          if req[field]?
            params = _.extend params, req[field]

        method params, (err, {name, content}) ->
          res.set('Content-Type', 'text/csv')
          res.set('Content-Disposition', "attachment;filename=#{name}.csv")
          res.send(content)

**webService**

    webService = (method, contentType = "application/json") ->
      (req, res) ->
        method getRequestParams(req), (err, data) ->
          if err?
            if (err instanceof BFError) then err.sendRes(res) else res.send 500
          else
            if data?.flashdata?
              req.flashdata = data.flashdata
              delete data.flashdata
            if contentType == "application/json"
              res.send data
            else if contentType == "jsonp"
              res.jsonp data
            else
              res.contentType contentType
              res.end data.toString()

**webPage**

    webPage = (template, method) ->
      (req, res) ->
        if not method? and template?
          data = getRequestParams(req)
          data.__ =
            template : template
          res.render template, data
        else
          method getRequestParams(req), (err, data) ->
            if err?
              res.send 500
            else if template?
              data = {} if not data?
              data.user = req.user if req.user? and not data.user?
              req.flashdata = data.flashdata if data.flashdata?
              data.__ =
                template : template
              res.render template, data
            else
              res.send data

**flashdata**


    flashdata = ->
      (req, res, next) ->
        if req?.session?.flashdata?
          _flashdata = req.session.flashdata
          delete req.session.flashdata

        Object.defineProperty req, "flashdata",
          get: -> _flashdata
          set: (newdata) -> req.session.flashdata = _flashdata = newdata

        next()

**memoryCache**


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

**Returns in a specific property of the params object**


    returns  = (method, property) ->
      (params, done) ->
        method params, (err, res) ->
          params[property] = res
          done err, params

**Combine with functions that only have a callback**


    mono  = (method) ->
      (params, done) ->
        method(done)


**Prepare**

    prepare = (method, first_arg) ->
      (params, done) ->
        method first_arg, done

Export public methods
---------------------

    module.exports =
      error            : bfError
      toDictionary     : toDictionary
      has              : has
      amap             : amap
      chain            : chain
      avoid            : avoid
      parallel         : parallel
      getRequestParams : getRequestParams
      csv       : csv
      webService       : webService
      webPage          : webPage
      webPagePost      : webPagePost
      flashdata        : flashdata
      memoize          : memoize
      nothing          : nothing
      returns          : returns
      mono             : mono
      prepare          : prepare
