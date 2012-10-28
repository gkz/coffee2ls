#!/usr/bin/env livescript
CoffeeScript = require \coffee-script
js2coffee = require \/usr/local/lib/node_modules/js2coffee/lib/js2coffee.coffee
coffee2ls = require \./lib/coffee2ls/module.js

escapeHTML = -> (it ? "").replace(/</g, '&lt;').replace(/>/g, '&gt;')
output = (params={}, result="") ->
    body = """
        <html><head><style>
            textarea {
                width: 100%;
                height: 300px;
            }
            input {
                width: 100%;
                font-size: 24px;
            }
        </style></head><body>#result<table width="100%"><tr>
    """
    for name, value of {
      js: 'Convert JavaScript'
      cs: 'Convert CoffeeScript'
    } => body += """
        <td>
            <form method="post"><p>
                <textarea name="#name">#{
                    escapeHTML params[name]
                }</textarea><br/>
                <input type="submit" value="#value">
            </p></form>
        </td>
    """
    body += "</tr></table>"
    return body

<- (require \zappajs)

@use \bodyParser, @app.router

@get '/' ->
    @send output!

@post '/' ->
    { js, cs } = @body
    src = if js? then js2coffee.build js else cs
    try
        tgt = coffee2ls.compile coffee2ls.parse src
    catch e
        tgt = "ERROR: #e"
    @send output {js, cs}, """
        <h1>LiveScript</h1><textarea>#{ escapeHTML tgt }</textarea><hr>
    """
