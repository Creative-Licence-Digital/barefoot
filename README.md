Barefoot
========

**barefoot** is a library that assists with the creation of large asynchronous
JavaScript applications, and, in particular, web applications using express.js.

It achieves this by encouraging the use of smaller, composable async functions
with a particular form called *bfunctions*.

Sample
------

```coffeescript
app.get '/shortener/:hash', bf.webMethod(shortener)

shortener = bf.chain -> [
  getUrl
  redirect
]

getUrl = ({ hash }, done) ->
  Url.findOne { hash }, done

redirect = (url, done) ->
  if url?
    done null, bf.redirect url.location
  else
    done null, bf.notFound()
```

Installing
----------

`npm install barefoot`

To use it

`bf = require 'barefoot'`

Intro
-----

### bfunctions

A *bfunction* is a function of the form
`fn(params: *, done: fn(err: *, res: *))`. That is, it is a function which takes
some parameters, performs some computation and then executes a callback function
with either the result of that computation or some error that occured.

### Errors

When calling an asynchronous function, resulting errors must always be handled.
barefoot provides several functions that make this less cumbersome.

We can use `bf.errorWrapper` to avoid writing error handling code in our
callbacks. The error will be passed up one level.

```coffeescript
getState = ({ id }, done) ->
  User.findById id, (err, user) ->
    if err? then return done err
    Address.findById user?.addressId, (err, address) ->
      if err? then return done err
      done null, address?.state
```

Can be rewritten:

```coffeescript
getState = ({ id }, done) ->
  w = bf.errorWrapper done
  User.findById id, w (user) ->
    Address.findById user?.addressId, w (address) ->
      done null, address?.state
```

### Sequences

To avoid heavily indented code ("callback hell"), we can use `bf.sequence` to
flatten our method.

The example above can be rewritten, with `bf.sequence`:

```coffeescript
getState = ({ id }, done) ->
  seq = bf.sequence done

  seq.then (next) ->
    User.findById id, next

  seq.then (next, user) ->
    Address.findById user?.addressId, next

  seq.then (next, address) ->
    next null, address?.state

  seq.end()
```

Or, if you prefer being explicit and mutating some function-level state:

```coffeescript
getState = ({ id }, done) ->
  seq = bf.sequence done

  [user, address] = []

  seq.then (next) ->
    User.findById id, seq.w (res) ->
      user = res
      next()

  seq.then (next) ->
    Address.findById user?.addressId, seq.w (res) ->
      address = res
      next()

  seq.then (next) ->
    done null, address?.state
```

`bf.sequence` will end the sequence if an error is passed to `next`.

### Chaining

Often a better approach to sequencing, however, is to break the method up into
smaller, more manageable chunks and chain them together.

The example above can be rewritten, with `bf.chain`:

```coffeescript
getState = bf.chain -> [
  getUser
  getAddress
  bf.get 'state'
]

getUser = ({ id }, done) ->
  User.findById id, done

getAddress = (user, done) ->
  Address.findById user?.addressId, done
```

`bf.chain` will automatically handle errors and stop execution if one occurs,
propogating it up to the caller.

barefoot contains several *bfunctions* that are useful when chained, such as
`bf.get`, used above.

Often it useful to to run two *bfunctions* concurrently in a chain.
`bf.parallel` achieves this nicely:

```coffeescript
getStateAndGroupName = bf.chain -> [
  getUser
  bf.parallel [
    bf.chain [
      getAddress
      bf.get 'state'
    ]
    bf.chain [
      getGroup
      bf.get 'name'
    ]
  ]
  bf.select ([state, name]) -> "State: {state} Name: {name}"

getUser = ({ id }, done) ->
  User.findById id, done

getAddress = (user, done) ->
  Address.findById user?.addressId, done

getGroup = (user, done) ->
  Group.findById user?.groupId, done
```

### Web methods

barefoot provides several methods that assists with the creation of web servers
and web sites using *bfunctions*.

These methods take a *bfunction* and run it with a HTTP request object as the
input. The output is then coerced to a `bf.HttpResponse` and this is used to
create an express.js callback function.

For example, this is a simple web application that echos the message given to
it:

```coffeescript
app.get '/echo/:message', bf.webService(echo)

echo = ({ message }, done) ->
  done null, message
```

`bf.webService` invokes the `echo` method with all of the request's URL, query
and POST parameters. The result of `echo` - a string - is coereced by
`bf.webService` into a 200 OK response that has the string and nothing else.

The following method demonstrates a few more complicated features by moving the
uploaded file 'image' and then redirecting to the page given in the X-Redirect
header:

```coffeescript
app.post '/foo', bf.webService(foo)

foo = (params, done) ->
  w = bf.errorWrapper done

  path = params.files.image.path
  fs.rename path, "images/{path.basename(path)}", w ->

    location = params.headers['X-Redirect'] ? '/'
    done null, bf.redirect location
```

If an error occurs during the *bfunction* that `bf.webService` executes, then a
HTTP 500 response is returned. If null is returned from the *bfunction*, then
HTTP 404 is returned.

`bf.webPage` performs a similar task, except the result of the *bfunction* is
passed to a view template. The *bfunction* is also optional, allowing 'static'
pages.

```coffeescript
app.get '/', bf.webPage('index')
app.get '/user/:id', bf.webPage('user', getUser)

getUser = ({ id }, done) ->
  User.findById id, done
```

API Reference
-------------

### Control flow bfunction builders

* **bf.chain**
  
  Composes bfunctions together, running each in sequence and giving the result
  of each function to the input of the next. If one bfunction in the chain has
  an error, the chain execution stops and the error is propogated up to the
  caller of the chain.

* **bf.parallel**
  
  Runs multiple bfunctions at the same time with the same input. An array of the
  results and errors is then returned.

* **bf.amap**

* **bf.sequence**

### General bfunction builders

* **bf.avoid**

  Wraps a function which does not return anything and has no callback in a
  bfunction callable in a chain.

* **bf.select**

  Turns a regular function into a bfunction.

### Object bfunction builders

* **bf.get**

  Creates a bfunction that retrieves the given property from its parameters.

### Array bfunction builders

* **bf.map**

  Creates a bfunction that, given an array, produces a new array according to
  some mapping function.

* **bf.reduce**

  Creates a bfunction that, given an array, produces a single value given some
  reduction function.

### Standard bfunctions

* **bf.identity**

  bfunction that does nothing (returns input).

### Web methods

* **bf.HttpResponse**

  A class which encodes possibly HTTP responses applied to an express.js
  response.

* **bf.redirect**

  Convenience method that creates a `bf.HttpResponse` which redirects to the
  given url.

* **bf.notFound**

  Convenience method that creates a `bf.HttpResponse` with HTTP code 404.

* **bf.webService**

  Takes a *bfunction* and returns an express.js callback which executes the
  *bfunction* with the web request as input and response as output.

* **bf.webPage**

  Takes a *bfunction* and returns an express.js callback which executes the
  *bfunction* with the web request as input. The output of the *bfunction* is
  pased into the given view template.

* **bf.middleware**

  Takes a *bfunction* and reeturns an express.js middleware callback which runs
  the *bfunction* and aborts the express.js handler if there was an error.

* **bf.memoize**

  Takes a *bfunction* and a number of seconds and gives back a *bfunction* that
  has its output cached for the given number of seconds based on the input.

Licence
-------

MIT

Authors
-------

Written by Mathieu Guillout and Robert Anderson-Butterworth at [Creative Licence
Digital](://www.creativelicencedigital.com/).
