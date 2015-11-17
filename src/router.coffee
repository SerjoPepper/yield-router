methods = require 'methods'
co = require 'co'
ExpressRouter = require('express').Router


wrap = (handler) ->
  nextFn = undefined

  executeHandler = (args...) ->
    co ->
      yield handler.apply(null, args)
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
