fs = require 'fs'
path = require 'path'

{formatParserError} = require './helpers'
Nodes = require './nodes'
{Preprocessor} = require './preprocessor'
Parser = require './parser'
codegen = require 'coffee2ls-codegen'
LiveScript = require 'LiveScript'

coffee2ls = null
pkg = require './../../package.json'


module.exports =
  Parser: Parser
  Preprocessor: Preprocessor
  Nodes: Nodes

  VERSION: pkg.version

  parse: (coffee, options = {}) ->
    try
      preprocessed = Preprocessor.processSync coffee
      parsed = Parser.parse preprocessed
    catch e
      unless options.suppress
        console.log 'Error parsing CoffeeScript'
      throw e unless e instanceof Parser.SyntaxError
      throw new Error formatParserError preprocessed, e

  js2coffee: (js, options = {js: {}}) ->
    try
      eval('require("js2coffee")').build js, options.js
    catch e
      unless options.suppress
        console.log 'Error with JavaScript -> CoffeeScript compilation'
        console.log js
      throw e

  ls: (csAst, options = {}) ->
    try codegen.generate csAst
    catch e
      unless options.suppress
        console.log 'Error with CoffeeScript AST -> LiveScript compilation'
        console.log csAst
      throw e

  compile: (csAst, options = {}) ->
    @ls csAst, options

  ls2js: (ls, options = {ls: {bare: true}}) ->
    try LiveScript.compile ls, options.ls
    catch e
      unless options.suppress
        console.log 'Error with LiveScript -> JavaScript compilation'
        console.log ls
      throw e

  coffee2js: (coffee, options = {}) ->
    @ls2js (@ls (@parse coffee, options), options), options

  run: (coffee, options) ->
    try eval @coffee2js coffee, options
    catch e
      unless options.suppress
        console.log 'Error attempting to eval JavaScript compiled from CoffeeScript'
        console.log coffee
      throw e


coffee2ls = module.exports.coffee2ls = module.exports

if require?.extensions?
  require.extensions['.coffee'] = (module, filename) ->
    input = fs.readFileSync filename, 'utf8'
    module._compile (coffee2ls.coffee2js input), filename

if window?
  window.coffee2ls = coffee2ls
