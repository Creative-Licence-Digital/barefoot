Barefoot
========

   
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



**amap**

Asynchronous map 
Use the awesome **lateral** module to do the job

    methods.amap = (func, nbProcesses) ->
      nbProcesses ?= 1
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

    global.Array.prototype.chain = (params, done, err) ->
      if @.length == 0
        done err, params
      else
        @[0] params, (err, res) =>
          if err?
            done err, res
          else
            @.slice(1, @.length).chain(res, done, err)



Export public methods
---------------------

    module.exports = methods
