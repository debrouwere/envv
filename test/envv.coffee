should = require 'should'
envv = require '../src'

example = __dirname + '/examples/basic/index.html'

it 'should filter out blocks of code that do not belong in the current environment: development', (done) ->
    envv.transform example, 'development', (errors, result) ->
        result.should.not.include 'data-environment'
        done()

it 'should filter out blocks of code that do not belong in the current environment: production', (done) ->
    envv.transform example, 'production', (errors, result) ->
        result.should.not.include 'data-cdn'
        done()
