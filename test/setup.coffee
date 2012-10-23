util = require 'util'
inspect = (o) -> util.inspect o, no, 2, yes

global[name] = func for name, func of require 'assert'

# See http://wiki.ecmascript.org/doku.php?id=harmony:egal
egal = (a, b) ->
  if a is b
    a isnt 0 or 1/a is 1/b
  else
    a isnt a and b isnt b

# A recursive functional equivalence helper; uses egal for testing equivalence.
arrayEgal = (a, b) ->
  if egal a, b then yes
  else if a instanceof Array and b instanceof Array
    return no unless a.length is b.length
    return no for el, idx in a when not arrayEgal el, b[idx]
    yes

global.eq      = (a, b, msg) -> ok egal(a, b), msg ? "#{inspect a} === #{inspect b}"
global.arrayEq = (a, b, msg) -> ok arrayEgal(a,b), msg ? "#{inspect a} === #{inspect b}"


libDir = if typeof _$jscoverage is 'undefined' then 'lib' else 'instrumented'

coffee2ls = require '..'
t = {}
t.coffee2js = (x) ->
  coffee2ls.coffee2js x, {suppress: true}
t.run = (x) ->
  coffee2ls.run x, {suppress: true}
t.parse = (x) ->
  coffee2ls.parse x, {suppress: true}
global.t = t
global.coffee2ls = coffee2ls


global.CS = require "../#{libDir}/coffee2ls/nodes"
global.Parser = require "../#{libDir}/coffee2ls/parser"
{Preprocessor} = require "../#{libDir}/coffee2ls/preprocessor"

global.parse = (input) -> Parser.parse Preprocessor.processSync input
