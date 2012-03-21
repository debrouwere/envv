should = require 'should'
cdn = require '../src/cdn'

q = new cdn.Query()

it 'should be able to convert pinned versions into potential CDN paths', ->
    refs = q.resolveSemverReference('jquery@1.7.1')
    refs.length.should.equal 4
    refs[0].should.equal 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js'

it 'should accept both paths and pinned versions and resolve them accordingly', ->
    refs = q.resolveReference '/vendor/underscore.js/1.7.1/underscore-min.js'
    refs[0].should.equal 'https://ajax.googleapis.com/ajax/libs/underscore.js/1.7.1/underscore.min.js'

it 'should accept hints when guessing does not work', (done) ->
    q.hint {'obscurelib@0.6.5': 'http://example.org/obscurity.js'}
    q.find 'obscurelib@0.6.5', (errors, locations) ->
        locations.length.should.equal 1
        should.exist q.cache.libraries['obscurelib@0.6.5']
        done()

it 'should handle `js` suffixes intelligently when guessing a library its location', ->
    refs = q.resolveReference 'spinejs@0.0.4'
    refs[0].should.equal 'https://ajax.googleapis.com/ajax/libs/spinejs/0.0.4/spine.min.js'
    refs = q.resolveReference 'underscore.js@a.b.c'
    refs[0].should.equal 'https://ajax.googleapis.com/ajax/libs/underscore.js/a.b.c/underscore.min.js'

it 'should test potential CDN paths to see which ones work if there is no cache', (done) ->
    q.cache.clean()
    q.find 'jquery@1.7.1', (errors, locations) ->
        locations.length.should.be.above 0
        done()
