fs = require 'fs'
path = require 'path'

{formatParserError} = require './helpers'
Nodes = require './nodes'
{Preprocessor} = require './preprocessor'
Parser = require './parser'
{Optimiser} = require './optimiser'
{Compiler} = require './compiler'
lscodegen = try require 'lscodegen'
escodegen = try require 'escodegen'
uglifyjs = try require 'uglify-js'
LiveScript = require 'LiveScript'


CoffeeScript = null
pkg = require path.join __dirname, '..', '..', 'package.json'

escodegenFormatDefaults =
  indent:
    style: '  '
    base: 0
  renumber: yes
  hexadecimal: yes
  quotes: 'auto'
  parentheses: no


module.exports =

  Compiler: Compiler
  Optimiser: Optimiser
  Parser: Parser
  Preprocessor: Preprocessor
  Nodes: Nodes

  VERSION: pkg.version

  parse: (coffee, options = {}) ->
    options.optimise ?= yes
    try
      preprocessed = Preprocessor.processSync coffee
      parsed = Parser.parse preprocessed
      if options.optimise then Optimiser.optimise parsed else parsed
    catch e
      throw e unless e instanceof Parser.SyntaxError
      throw new Error formatParserError preprocessed, e

  compile: (csAst, options) ->
    Compiler.compile csAst, options

  # TODO
  cs: (csAst, options) ->
    # TODO: opt: format (default: nice defaults)

  ls: (csAst, options) ->
    handleNodes = (node, o, inFunc) ->
      if node.className is 'Function'
        o = o[..]
        inFunc = []
      if node.className in ['AssignOp', 'ExistsAssignOp'] and node.assignee.className is 'Identifier'
        name = node.assignee.data
        if name in o and name not in inFunc
          node.reassign = true
        else
          push = true
      for k, child of node when child?.instanceof?
        handleNodes child, o, inFunc
      for k in node.listMembers
        for child in node[k]
          handleNodes child, o, inFunc
      if push
        o.push name
        inFunc.push name
      undefined

    handleNodes csAst, [], []
    lscodegen.generate csAst

  ls2js: (code) ->
    LiveScript.compile code

  js: (jsAst, options = {}) ->
    # TODO: opt: minify (default: no)
    throw new Error 'escodegen not found: run `npm install escodegen`' unless escodegen?
    escodegen.generate jsAst,
      comment: yes
      format: options.format ? escodegenFormatDefaults

  sourceMap: (jsAst, name = 'unknown', options = {}) ->
    throw new Error 'escodegen not found: run `npm install escodegen`' unless escodegen?
    escodegen.generate jsAst.toJSON(),
      comment: yes
      sourceMap: name
      format: options.format ? escodegenFormatDefaults

CoffeeScript = module.exports.CoffeeScript = module.exports


require.extensions['.coffee'] = (module, filename) ->
  input = fs.readFileSync filename, 'utf8'
  csAst = CoffeeScript.parse input, {optimise: no}
  ls = CoffeeScript.ls csAst
  js = CoffeeScript.ls2js ls
  module._compile js, filename
