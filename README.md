# Envv

[![Build Status](https://secure.travis-ci.org/stdbrouw/envv.png)](http://travis-ci.org/stdbrouw/envv)

Envv allows you to change how your client-side code works depending on whether it's in a development or production environment. The same concept you love from server-side coding, except now you can use it in your front-end projects.

Envv also makes it easy to use public CDNs to host popular JavaScript libraries in production.

In the future, Envv may (or may not) work in the browser. Currently, Envv is implemented as an HTML preprocessor in node.js, accessible programmatically and through a command-line interface.

## Example

    <link rel="stylesheet" href="grid-debug.css" data-environment="development" /> 
    <script
        src="jquery.js"
        data-cdn="https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js">
    </script>
    <script
        src="underscore.js"
        data-cdn="underscore@1.3.1">
    </script>
    <script data-environment="production">
        (function() {
        var ga = document.createElement('script');
        ga.src = ('https:' == document.location.protocol ?
            'https://ssl' : 'http://www') +
            '.google-analytics.com/ga.js';
        ga.setAttribute('async', 'async');
        document.documentElement.firstChild.appendChild(ga);
        })();
    </script>

## Usage

Environment-specific functionality or html is indicated using data attributes.

    data{-prefix}-environment       # development is a special value, everything else is up to you
    data{-prefix}-environment-block # specify this when you want to consume the tag the environment is attached to
    data{-prefix}-runtime           # does the replacement if env is anything other than development
    data{-prefix}-cdn               # similar to runtime, but you don't have to specify a full URL, 
                                    # but instead you can do e.g. data-cdn="jquery@1.7.2"
                                    # and it will check the two major public CDN's
                                    # (Google and CloudFlare)
                                    # (though if you pass a full URL, it'll act like a more semantic
                                    # version of data-runtime instead)

By default, Envv will search for attributes like `data-environment`, `data-cdn` and so on, but if you prefer, you can add whatever namespace prefix you like. Just make sure to specify your prefix (if any) on the command-line or when using the API, so envv knows you're using one.

You can specify multiple environments in an environment attribute. For example, if you want to leave debugging on in your staging environment, you could do something like

    <script data-environment="development staging">
        var MyApp.debug = true;
    </script>

`data-cdn` is very versatile: you can specify a path (e.g. `https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js`, a pinned version (e.g. `jquery@1.7.1`) or you can leave it blank (e.g. `<script src="/libs/jquery/1.7.1/jquery.min.js" data-cdn></script>`) in which case Envv will try to divine the library you want to "cdnify" from the path to your local version in `src`.

Scroll down to the "advanced usage" section to learn more.

## CLI

Envv is accessible through the command-line. For example: 

    envv test/examples/basic/index.html -e development

To find out more, do `envv --help`

## API

Transform your HTML to conform to an environment: 

    # basic usage (in CoffeeScript)
    fs = require 'fs'
    fs.path = require 'path'
    envv = require 'envv'
    here = (path) -> fs.path.join __dirname, path

    # can be a URL or a string of HTML
    app = here 'index.html'
    envv.transform app, 'production', (errors, html) ->
        fs.writeFileSync (here 'index-production.html'), html

In a bit more detail, with various options: 

    # currently `envv.transform` only works on an individual file, not a directory
    # (though the CLI does both)
    location = here 'index.html'
    # specify the environment you wish to activate
    environment = 'production'
    # if you want envv to act on namespaced data attributes, you can specify a prefix
    # in this case `data-envv-environment` (et cetera) instead of just `data-environment`
    prefix = 'envv'
    # envv is asynchronous, so you need to specify a callback
    callback = (errors, html) -> console.log html
    envv.transform app, environment, prefix, callback

Find the location of popular JavaScript libraries on Google and CloudFlare's public CDNs.

    # basic usage
    envv = require 'envv'
    q = new envv.cdn.Query()
    q.find 'jquery@1.7.1', (errors, locations) ->
        # returns an array of hotlinkable URLs where you can find
        # the library, in this case version 1.7.1 of jQuery.
        console.log locations

    # passing in a local path to a library that you want to find a public equivalent of
    # works too, as long as the last part of the path adheres to the format 
    # `<library>/<version>/<library>.min.js`
    q.find '/my/local/jquery/1.7.1/jquery.min.js', (errors, locations) ->
    
    # envv caches library locations locally
    # you can clear that cache if for some reason you need to
    q.cache.clear()
    q.cache.save()

You can also take a look at the unit and integration tests in the `envv/test` directory to get a better feel for the API.

## Advanced use

### Using data-cdn

There are three different ways you can use data-cdn, to suit different requirements.

#### No specification

No specification means you just do `<script src="/myproject/vendor/underscore/1.3.1/underscore-min.js" data-cdn></script>`

Your vendor dir during development follows the common CDN directory layout, 

    <script>/<version>/<script-without-suffix>.min.js

or

    <script>/<version>/<script-without-suffix>-min.js

"Without suffix" means that `backbone.js` becomes `backbone`, and `datejs` becomes `date`. So your backbone.js file should reside at `/backbone.js/0.9.1/backbone-min.js`

Any base directory works, so for example /myproject/vendor/underscore/1.3.0/underscore-min.js is ok. Envv will simply find out if the Google or CloudFlare CDNs have the library you're looking for.

This option is especially useful when you're using [Draughtsman]() or the [Mimeo]() local mirror during development, as those tools will make popular JavaScript scripts available at exactly those paths.

#### Full specification

You can specify a full URL. This is equivalent to `data-runtime`.

    <script src="underscore.min.js" data-cdn="http://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.3.1/underscore-min.js"></script>

#### Pinned version

You can specify a project and its version number, and Envv will try to find that project in a public CDN.

    <script src="underscore.min.js" data-cdn="underscore@1.3.1"></script>

See [the semver website](http://semver.org/) for more information about how semantic version numbering works.

### Customizing the search path

By default, Envv will search https://ajax.googleapis.com/ajax/libs and http://cdnjs.cloudflare.com/ajax/libs. You can change where Envv looks with the `--networks` parameter on the commandline, or the networks argument to cdn.find in the API.

Whenever Envv first encounters a particular semver reference or an incompletely specified reference, it will query public CDNs to see whether they have what you're looking for. But a minority of projects use unexpected filenames and Envv can't find those. For example labjs is available as `LAB.min.js` on the CloudFlare CDN. You can provide Envv with a hint as to where to find things.

    # with hinting (use when envv can't find a library's location, either because it
    # has a weird filename on a public CDN or because you want to use your own CDN)
    q.hint {'obscurelib@0.6.5': 'http://example.org/obscurity.js'}
    q.find('obscurelib@0.6.5', function (locations) {
        locations.length.should.equal(1);
    });

    # as part of `envv.transform`
    hints =
        'obscurelib@0.6.5': 'http://example.org/obscurity.js'
        'jquery@1.7.1': 'http://example.org/jquery.js'
    
    envv.transform app, environment, prefix, hints, (errors, html) ->
        console.log html

Or through the command-line

    envv --hint labjs@2.0.3:http://cdnjs.cloudflare.com/ajax/libs/labjs/2.0.3/LAB.min.js
    envv --hint privatelib@0.3.0rc:http://static.example.org/libs/dev/privatelib.min.js

You can use as many hints as you like: just separate key-value pairs with a comma.

### How the cache works

Whenever you add a new external library and specify a `data-cdn` without a full URL (e.g. using a pinned version like `jquery@1.7.1`), Envv needs an internet connection to actually make sure that the thing you need is available on a public content delivery network. Envv will keep this information cached, so it's a one-time thing, but keep it in mind.
