#!/usr/bin/env livescript
CoffeeScript = require \coffee-script
js2coffee = require \./node_modules/js2coffee/lib/js2coffee.coffee
coffee2ls = require \./lib/coffee2ls/module.js

escapeHTML = -> (it ? "").replace(/</g, '&lt;').replace(/>/g, '&gt;')
output = (src="""
/* Type here! */

(function ($) {
    $.fn.highlight = function () {
        $(this).css({ color: 'red', background: 'yellow' });
        $(this).fadeIn();
    };
})(jQuery);
""", tgt="", cs=no) ->
    body = """<html><head>
        <link href="http://js2ls.org/css/reset.css" rel="stylesheet" type="text/css">
        <link href="http://js2ls.org/css/style.css" rel="stylesheet" type="text/css">
<style>
li input {
    display:inline-block;
    border-radius: 25px;
    font-weight: bold;
    padding:5px 10px 5px 10px;
    text-shadow: 0 1px 0 \#FFF;
}
li input:hover {
    background: white;
}
</style>
</head><body><div id="container" style="height: auto">
          <form method="post">
              <div id="js2ls" class="tab">
                <textarea name="src">#{ escapeHTML src }</textarea>
                <textarea readonly name="">#{ escapeHTML tgt }</textarea>
              </div>
<div id="tabs">
<ul>
<li style="float: right; margin-right: 20px">
<a target="_blank" href="http://livescript.net/"><img height="30" src="https://s3.amazonaws.com/github/downloads/gkz/LiveScript/logo.png"></a>
</li>
<li class="#{ if cs then '' else \selected }">
    <input type="submit" name="js" value="Convert JavaScript">
</li><li class="#{ if cs then \selected else '' }">
    <input type="submit" name="cs" value="Convert CoffeeScript">
</li></ul>
</div>
          </form>
        </div>
    """
    body += "</body></html>"
    return body

<- (require \zappajs)

@use \bodyParser, @app.router

@get '/' ->
    @send output!

@post '/' ->
    { js, cs, src } = @body
    try
        coffee = if js then js2coffee.build src else src
        tgt = coffee2ls.compile coffee2ls.parse coffee
    catch e
        tgt = "ERROR: #e"
    @send output src, tgt, cs
