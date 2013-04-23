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



Let's get started
------------------

We declare an object to contain all the methods we want to export from this  module

    methods = {}



**toDictionary** 

Transform an array of object into a dictionary based on the property passed as a second param

    methods.toDictionary = (array, prop) ->
      dictionary = {}
      array.forEach (elt) -> 
        dictionary[elt[prop]] = elt if elt? and elt[prop]?
      return dictionary



**has**

Provides a function which test if parameters object has certain properties

    methods.has = (parameters) ->
      (params, done) ->
        ok = true
        ok = (ok and params? and params[par]?) for par in parameters
        done (if ok then null else new Error("Missing Parameters")), params


**amap**

Asynchronous map 
Use the awesome **lateral** module to do the job

    methods.amap = (func, nbProcesses = 1) ->
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

    methods.chain = (funcs) -> 
      (params, done, err) ->
        if funcs.length == 0
          done err, params
        else
          funcs[0] params, (err, res) =>
            if err?
              done err, res
            else
              methods.chain(funcs.slice(1, funcs.length))(res, done, err)



Export public methods
---------------------

    module.exports = methods
