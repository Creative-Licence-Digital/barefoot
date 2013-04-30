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
          done errors, results

**chain**

Chain aynschronous methods with signature (params, done) -> done(err, result)
Stop if one of the method has an error in the callback

    chain = (funcs) -> 
      (params, done, err) ->
        if funcs.length == 0
          done err, params
        else
          funcs[0] params, (err, res) =>
            if err?
              done err, res
            else
              methods.chain(funcs.slice(1, funcs.length))(res, done, err)


**avoid**

Wrap a void returning function to make it callable in a chain

    avoid = (func) ->
      (params, done) ->
        func(params)
        done null, params 


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
      for field in ["body", "query", "params"]
        if req[field]?
          params = _.extend params, req[field]
      params.user = req.user if req.user?
      params


**webService**

    webService = (method, contentType = "application/json") ->
      (req, res) ->
        method getRequestParams(req), (err, data) ->
          if err? 
            res.send 500
          else
            if contentType == "application/json"
              res.send data
            else
              res.contentType contentType
              res.end data.toString()

**webPage**

    webPage = (template, method) ->
      (req, res) ->
        if not method? and template?
          res.render template, getRequestParams(req)
        else
          method getRequestParams(req), (err, data) ->
            if err?
              res.send 500
            else
              data = {} if not data?
              data.user = req.user if req.user? and not data.user?
              res.render template, data


Export public methods
---------------------

    module.exports =
      toDictionary : toDictionary
      has          : has
      amap         : amap
      chain        : chain
      avoid        : avoid
      parallel     : parallel
      webService   : webService
      webPage      : webPage

