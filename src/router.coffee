methods = require 'methods'
co = require 'co'
promise = require 'bluebird'
ExpressRouter = require('express').Router

isGenerator = (fn) ->
  'function' is typeof fn.next && 'function' is typeof fn.throw;

wrap = (handler) ->
  nextFn = undefined

  executeHandler = (args...) ->
    co ->
      if isGenerator(handler)
        yield handler.apply(null, args)
      else
        promise.resolve handler.apply(null, args)
    .then(
      (nextArg) ->
        switch nextArg
          when 'route'
            nextFn('route')
          when 'next'
            nextFn()
      (err) ->
        nextFn(err)
    )

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
  router = new ExpressRouter(path)
  for method in methods.concat(['use', 'all', 'param'])
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
