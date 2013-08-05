_ = require 'underscore'

fail = (reason) ->
  ok: false, reason: reason

checkObject = (pathPrefix, object, schema) ->
  for key, type of schema

    optional = key[0] == '_'
    if optional
      key = key[1..]

    value = object[key]

    path = if pathPrefix then "#{pathPrefix}.#{key}" else key

    if not optional and not value?
      return fail "#{path} is required"

    if not value?
      continue

    if _.isFunction type
      vs =
        Number:  _.isNumber
        String:  _.isString
        Array:   _.isArray
        Boolean: _.isBoolean
        Object:  _.isObject

      if type.name of vs
        if not vs[type.name](value)
          return fail "#{path} is not a #{type.name}"
      else
        if not type value
          return fail "#{path} is invalid"

    if _.isRegExp type
      if not type.test value
        return fail "#{path} does not match #{type}"

    if _.isArray(type) and type.length == 1
      if _.some(value, (v) -> not check v, type[0])
        return fail "#{path} is invalid" # todo: better message

    if _.isArray(type) and type.length > 1
      if value not in type
        return fail "#{path} is invalid" # todo: better message

    if _.isObject type
      c = checkObject path, value, type
      if not c.ok
        return fail c.reason

  return ok: true

check = (object, schema) ->
  checkObject null, object, schema

module.exports = check
