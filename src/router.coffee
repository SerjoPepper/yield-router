Router = require('express').Router
Promise = require('bluebird')
_ = require('lodash')
co = require('co')

isPromise = (obj) ->
  obj and 'object' == typeof obj and obj.then != undefined

isGenerator = (fn) ->
  fn and 'function' == typeof fn.next and 'function' == typeof fn['throw']

wrapHandler = (handler) ->

  handleReturn = (args) ->
    next = args.slice(-1)[0]
    ret = handler.apply(null, args)
    _promise = undefined
    if isPromise(ret)
      _promise = ret
    else if isGenerator(ret)
      _promise = co.wrap(handler).apply(null, args)
    if _promise
      _promise.then ((d) ->
        if d == 'next'
          next()
        else if d == 'route'
          next 'route'
        return
      ), (err) ->
        if !err
          err = new Error('returned promise was rejected but did not have a reason')
        next err
        return
    return

  if handler.length == 4
    return (err, req, res, next) ->
      handleReturn [
        err
        req
        res
        next
      ]
      return

  (req, res, next) ->
    handleReturn [
      req
      res
      next
    ]
    return

PromiseRouter = (path) ->
  me = new Router(path)
  methods = require('methods').concat([
    'use'
    'all'
    'param'
  ])
  _.each methods, (method) ->
    original = '__' + method
    me[original] = me[method]

    me[method] = ->
      args = _.flattenDeep(arguments).map((arg, idx) ->
        if idx == 0 and 'string' == typeof arg or arg instanceof RegExp
          return arg
        wrapHandler arg
      )
      me[original].apply this, args

    return
  me

module.exports = PromiseRouter
