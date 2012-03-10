###
q = new exports.Query()
q.find 'jquery@1.7.1', (location) ->
    console.log location
    console.log q.cache.libraries

q.hint {'obscurelib@0.6.5': 'http://example.org/obscuritas.js'}
q.find 'obscurelib@0.6.5', (location) ->
    console.log location
    console.log q.cache.libraries

console.log q.resolveSemverReference 'jquery@1.7.1'
q.find 'jquery@1.7.1', (location) ->
    console.log location

console.log q.resolveSemverReference 'underscore.js@1.7.1'
q.find 'underscore.js@1.3.1', (location) ->
    console.log location

console.log q.resolveSemverReference 'spinejs@0.0.4'
q.find 'spinejs@0.0.4', (location) ->
    console.log location
###
