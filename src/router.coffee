promise = require 'bluebird'
methods = require 'methods'
ExpressRouter = require('express').Router

wrap = (handler) ->
  nextFn = undefined

  executeHandler = (arguments) ->
    promise.coroutine ->
      yield handler.apply(null, arguments)
    .then (nextArg) ->
      switch nextArg
        when 'route'
          nextFn('route')
        when 'next'
          nextFn()
    .catch (err) ->
      nextFn(err)

  wrapNext = (next) ->
    nextFn = next

  switch handler.length
    when 4
      (err, req, res, next) ->
        executeHandler(err, req, res, wrapNext(next))
    else
      (req, res, next) ->
        executeHandler(req, res, wrapNext(next))


YieldRouter = (path) ->
  router = new ExpressRouter()
  for method in methods.concat(['use', 'all', 'params'])
    do (method) ->
      original = router[method]
      router[method] = (args...) ->
        args = args.map (arg, i) ->
          if typeof arg is 'function'
            wrap(arg)
          else
            arg

        original.apply(router, args)
  router

module.exports = YieldRouter