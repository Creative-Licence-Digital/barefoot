_ = require 'underscore'

checkValue = (value, type) ->
  if type is Number and not _.isNumber value then return false
  if type is String and not _.isString value then return false
  if type is Array and not _.isArray value then return false
  if type is Boolean and not _.isBoolean value then return false
  if type is Object and not _.isObject value then return false

  if _.isRegExp type
    if not type.test value
      return false

  if _.isArray(type) and type.length == 1
    if _.some(value, (v) -> not checkValue v, type[0])
      return false

  if _.isArray(type) and type.length > 1
    if value not in type
      return false

  if _.isObject type
    if not checkObject value, type
      return false

  if _.isFunction type
    if not type value
      return false

  return true

checkObject = (object, schema) ->
  for key, type of schema

    optional = key[0] == '_'
    if optional
      key = key[1..]

    value = object[key]

    if not optional and not value?
      return false

    if not value?
      continue

    if not checkValue value, type
      return false

  return true

module.exports = checkObject
