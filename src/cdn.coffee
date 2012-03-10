fs = require 'fs'
fs.path = require 'path'
async = require 'async'
request = require 'request'

NETWORKS = [
    'https://ajax.googleapis.com/ajax/libs'
    'http://cdnjs.cloudflare.com/ajax/libs'
    ]

has_file = (location, callback) ->
    request.head location, (error, response, body) ->
        callback response.statusCode is 200

class exports.Cache
    constructor: (path) ->
        @path = fs.path.join __dirname, path
        @libraries = {}
        if fs.path.existsSync @path then @load()

    load: ->
        cache = fs.readFileSync @path, 'utf8'
        @libraries = JSON.parse cache
        this

    save: ->
        json = JSON.stringify @libraries, undefined, 4
        fs.writeFileSync @path, json, 'utf8'
        this

    clean: ->
        @libraries = {}
        this

    add: (spec, uri) ->
        @libraries[spec] ?= []
        i = @libraries[spec].indexOf uri
        # if this library is already in our cache, we keep it but move it to the top
        if i > -1
            @libraries[spec].splice i, 1
        @libraries[spec].unshift uri
        this

    remove: (libraries...) ->
        for library in libraries
            if library of @libraries
                delete @libraries[library]

    find: (path_or_specification) ->
        if (path_or_specification.indexOf '/') isnt -1
            # TODO: properly implement
            specification = convert_to_spec path_or_specification
        else
            specification = path_or_specification

        if @libraries[specification]?
            return @libraries[specification]
        else
            return null

class exports.Query
    constructor: (@networks = NETWORKS, hints = {}, cachepath = '../cache.json') ->
        @cache = new exports.Cache cachepath
        (@cache.add reference, uri) for reference, uri of hints
        @cache.save()

    resolveSemverReference: (reference) ->
        [name, version] = reference.split '@'
        basename = name.replace(/(\.|\-)?js/, '')
        potential_filenames = [
            basename + '.min.js'
            basename + '-min.js'
            ]

        references = []
        @networks.map (network) ->
            for filename in potential_filenames
                references.push [network, name, version, filename].join('/')

        return references

    hint: (hints) ->
        (@cache.add reference, uri) for reference, uri of hints
        @cache.save()

    find: (reference, callback) ->
        cache = @cache.find reference
        if cache
            callback cache
            return
    
        async.filter (@resolveSemverReference reference, @networks), has_file, (locations) =>
            if locations.length > 0
                # update cache
                (@cache.add reference, location) for location in locations
                @cache.save()
            
            # call back with what we've found
            callback locations
