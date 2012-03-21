should = require 'should'
envv = require '../src'

example = __dirname + '/examples/basic/index.html'

it 'should filter out blocks of code that do not belong in the current environment', (done) ->
    envv.transform example, 'development', (errors, result) ->
        console.log result
        done()

it 'should filter out blocks of code that do not belong in the current environment II', (done) ->
    envv.transform example, 'production', (errors, result) ->
        console.log result
        done()
