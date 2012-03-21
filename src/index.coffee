cdn = require './cdn'
jsdom = require 'jsdom'
fs = require 'fs'
fs.path = require 'path'
_ = require 'underscore'
async = require 'async'

jquery = fs.path.join __dirname, '../vendor/jquery/1.7.1/jquery.min.js'

cdnQuery = new cdn.Query()
processReference = _.bind cdnQuery.find, cdnQuery

# TODO: check whether we're dealing with a directory or an individual file

class Page
    constructor: (@uri, @environment, @prefix = '') ->

    # getter/setter
    html: (window) ->
        if window?
            @_html = window.document.outerHTML
        else
            @_html

    # TODO: refactor / split this up a bit
    process: (callback) ->
        {environment, prefix} = @
        if prefix.length then prefix += '-'
        prefixed = (str) ->
            prefix + str

        data = (str) ->
            'data-' + prefixed str
    
        jsdom.env @uri, [jquery], (errors, window) =>
            $ = window.$

            # process environments      
            $("*").each ->
                el = $ @
                environments = el.data(prefixed 'environment') or el.data(prefixed 'environment-block')
                isBlock = el.data(prefixed 'environment-block').length isnt 0
                return unless environments.length

                environments = environments.split(' ')
          
                if environments.indexOf(environment) isnt -1
                    if isBlock
                        el.replaceWith el.children()
                    else
                        el.removeAttr data 'environment'
                else
                    el.remove()
                    
            # process runtimes
            $("script").add("link").each ->
                el = $ @
                runtime = el.data(prefixed 'runtime')
                return unless runtime.length
                el.removeAttr data 'runtime'
                if el.is('link')
                    el.attr 'href', runtime
                else
                    el.attr 'src', runtime

            close = (errors) =>
                $('.jsdom').remove()
                @html window
                window.close()
                callback errors

            # TODO: think about whether this is the expected behavior, 
            # and if so, whether it should apply to runtimes too (probably)
            return close() if environment is 'development'

            # preprocess CDN references
            links = $("script").add("link")
                .filter ->
                    $(this).data(prefixed 'cdn').length isnt 0     
                .each ->
                    # data-cdn="data-cdn" simply means `true`, so we use the 
                    # script or link source instead to figure out what to replace
                    # this element with
                    el = $ @
                    reference = el.data(prefixed 'cdn')
                    source = el.attr('src') or el.attr('href')
                    if reference is ('data-' + prefixed 'cdn') then reference = source
                    el.data (prefixed 'cdn'), reference            

            # process CDN references
            process = (link, done) ->
                el = $(link)
                reference = el.data prefixed 'cdn'
                processReference reference, (errors, locations) ->
                    return done() unless locations.length

                    if el.is('link')
                        el.attr 'href', locations[0]
                    else
                        el.attr 'src', locations[0]
                    el.removeAttr data 'cdn'
                    
                    done()
            
            async.forEach links.get(), process, close

exports.transform = (params..., callback) ->
    page = new Page params...
    tasks = [
        page.process
        ]
    tasks = tasks.map (task) -> _.bind task, page

    async.series tasks, (errors) ->
        callback errors, page.html()

example = fs.path.join __dirname, '../test/examples/basic/index.html'
