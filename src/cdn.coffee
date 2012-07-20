fs = require 'fs'
fs.path = require 'path'
async = require 'async'
request = require 'request'
_ = require 'underscore'
mkdirp = require 'mkdirp'

NETWORKS = [
    'https://ajax.googleapis.com/ajax/libs'
    'http://cdnjs.cloudflare.com/ajax/libs'
    ]

hasFile = (location, callback) ->
    request.head location, (error, response, body) ->
        callback response.statusCode is 200

class exports.Cache
    constructor: (path) ->
        @path = fs.path.join __dirname, path
        base = fs.path.dirname @path
        mkdirp.sync base
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

    clear: ->
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

    find: (specification) ->
        if @libraries[specification]?
            return @libraries[specification]
        else
            return null

class exports.Query
    constructor: (@networks = NETWORKS, hints = {}, cachepath = '../cache/cache.json') ->
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

    toSemver: (path) ->
        if path.indexOf('@') isnt -1
            path
        else
            segments = path.split('/')
            if segments.length < 3
                throw new Error "Can't resolve #{path} into a Semver reference"

            [base..., script, version, filename] = segments
            "#{script}@#{version}"            

    resolvePathReference: (path) ->
        semver = @toSemver path
        @resolveSemverReference semver

    resolveReference: (reference) ->
        if (reference.indexOf '/') isnt -1
            @resolvePathReference reference
        else if (reference.indexOf '@') isnt -1
            @resolveSemverReference reference
        else
            new Error "This reference is not a path or a semver reference, and can't be resolved"

    hint: (hints) ->
        (@cache.add reference, uri) for reference, uri of hints
        @cache.save()

    find: (reference, callback) ->
        reference = @toSemver reference
        cache = @cache.find reference
        if cache
            callback null, cache
            return

        # don't spam the public CDNs we query
        niceHasFile = _.debounce hasFile, 250

        async.filter (@resolveReference reference, @networks), hasFile, (locations) =>
            if locations.length > 0
                # update cache
                (@cache.add reference, location) for location in locations
                @cache.save()
            
            # call back with what we've found
            callback null, locations
