fs = require 'fs'
path = require 'path'
{concat, foldl} = require './functional-helpers'
{numberLines, humanReadable} = require './helpers'
{Preprocessor} = require './preprocessor'
coffee2ls = require './module'

inspect = (o) -> (require 'util').inspect o, no, 9e9, yes

# clone args
args = process.argv[1 + (process.argv[0] is 'node') ..]

# ignore args after --
additionalArgs = []
if '--' in args then additionalArgs = (args.splice (args.indexOf '--'), 9e9)[1..]


# initialise options
options = {}
optionMap = {}

optionArguments = [
  [['js',      'j'], off, 'input is JavaScript (not CoffeeScript)']
  [['debug'       ], off, 'output intermediate representations on stderr for debug']
  [['version', 'v'], off, 'display the version number']
  [['help',    'h'], off, 'display this help message']
]

parameterArguments = [
  [['cli',     'c'], 'INPUT', 'pass a string from the command line as input']
  [['input',   'i'], 'FILE' , 'file to be used as input instead of STDIN']
  [['output',  'o'], 'FILE' , 'file to be used as output instead of STDIN']
  [['watch',   'w'], 'FILE' , 'watch the given file/directory for changes']
]

shortOptionArguments = []
longOptionArguments = []
for opts in optionArguments
  options[opts[0][0]] = opts[1]
  for o in opts[0]
    optionMap[o] = opts[0][0]
    if o.length is 1 then shortOptionArguments.push o
    else if o.length > 1 then longOptionArguments.push o

shortParameterArguments = []
longParameterArguments = []
for opts in parameterArguments
  for o in opts[0]
    optionMap[o] = opts[0][0]
    if o.length is 1 then shortParameterArguments.push o
    else if o.length > 1 then longParameterArguments.push o


# define some regexps that match our arguments
reShortOptions = ///^ - (#{shortOptionArguments.join '|'})+ $///
reLongOption = ///^ -- (no-)? (#{longOptionArguments.join '|'}) $///
reShortParameter = ///^ - (#{shortParameterArguments.join '|'}) $///
reLongParameter = ///^ -- (#{longParameterArguments.join '|'}) $///
reShortOptionsShortParameter = ///
  ^ - (#{shortOptionArguments.join '|'})+
  (#{shortParameterArguments.join '|'}) $
///


# parse arguments
positionalArgs = []
while args.length
  arg = args.shift()
  if reShortOptionsShortParameter.exec arg
    args.unshift "-#{arg[1...-1]}", "-#{arg[-1..]}"
  else if reShortOptions.exec arg
    for o in arg[1..].split ''
      options[optionMap[o]] = on
  else if match = reLongOption.exec arg
    options[optionMap[match[2]]] = if match[1]? then off else on
  else if match = (reShortParameter.exec arg) ? reLongParameter.exec arg
    options[optionMap[match[1]]] = args.shift()
  else if match = /^(-.|--.*)$/.exec arg
    console.error "Unrecognised option '#{match[0].replace /'/g, '\\\''}'"
    process.exit 1
  else
    positionalArgs.push arg

positionalArgs = positionalArgs.concat additionalArgs
if positionalArgs.length
  options.input = positionalArgs.shift()
  additionalArgs = positionalArgs

# - i (input), w (watch), cli
if 1 < options.input? + options.watch? + options.cli?
  console.error 'Error: At most one of --input (-i), --watch (-w), or --cli may be used.'
  process.exit 1

# dependencies
# - I (require) depends on e (eval)
if options.require? and not options.eval
  console.error 'Error: --require (-I) depends on --eval (-e)'
  process.exit 1

# - i (input) depends on o (output) when input is a directory
if options.input? and (fs.statSync options.input).isDirectory() and (not options.output? or (fs.statSync options.output)?.isFile())
  console.error 'Error: when --input is a directory, --output must be provided, and --output must not reference a file'

# start processing options
if options.help
  $0 = if process.argv[0] is 'node' then process.argv[1] else process.argv[0]
  $0 = path.basename $0
  maxWidth = 85

  wrap = (lhsWidth, input) ->
    rhsWidth = maxWidth - lhsWidth
    pad = (Array lhsWidth + 4 + 1).join ' '
    rows = while input.length
      row = input[...rhsWidth]
      input = input[rhsWidth..]
      row
    rows.join "\n#{pad}"

  formatOptions = (opts) ->
    opts = for opt in opts when opt.length
      if opt.length is 1 then "-#{opt}" else "--#{opt}"
    opts.sort (a, b) -> a.length - b.length
    opts.join ', '

  console.log """
    Usage:
      TODO: usage
  """

  optionRows = for opt in optionArguments
    [(formatOptions opt[0]), opt[2]]
  parameterRows = for opt in parameterArguments
    ["#{formatOptions opt[0]} #{opt[1]}", opt[2]]
  leftColumnWidth = foldl 0, [optionRows..., parameterRows...], (memo, opt) ->
    Math.max memo, opt[0].length

  rows = [optionRows..., parameterRows...]
  rows.sort (a, b) ->
    a = a[0]; b = b[0]
    if a[0..1] is '--' and b[0..1] isnt '--' then return 1
    if b[0..1] is '--' and a[0..1] isnt '--' then return -1
    if a.toLowerCase() < b.toLowerCase() then -1 else 1
  for row in rows
    console.log "  #{row[0]}#{(Array leftColumnWidth - row[0].length + 1).join ' '}  #{wrap leftColumnWidth, row[1]}"

  console.log """
    Unless instructed otherwise (--{input,watch,cli}), `#{$0}` will operate on stdin/stdout.
  """

else if options.version
  pkg = require './../../package.json'
  console.log "coffee2ls version #{pkg.version}"

else if options.repl
  # TODO: start repl
  console.error 'TODO: REPL'
  process.exit 1

else
  # normal workflow
  input = ''

  processInput = (err) ->
    throw err if err?
    result = null

    input = input.toString()
    # strip UTF BOM
    if 0xFEFF is input.charCodeAt 0 then input = input[1..]

    # --js
    if options.js
      try input = coffee2ls.js2coffee input
      catch e
        console.log e.message
        process.exit 1

    # preprocess
    if options.debug
      try
        console.log '### PREPROCESSED CS ###'
        console.log numberLines humanReadable Preprocessor.processSync input

    # parse
    try result = coffee2ls.parse input
    catch e
      console.error e.message
      process.exit 1

    if options.debug and result?
      console.error "### PARSED CS-AST ###"
      console.error inspect result.toJSON()

    # codegen
    try result = coffee2ls.compile result
    catch e
      console.error (e.stack or e.message)
      process.exit 1
    if result?
      console.log result
      process.exit 0
    else
      process.exit 1

  # choose input source
  if options.input?
    # TODO: handle directories
    fs.readFile options.input, (err, contents) ->
      throw err if err?
      input = contents
      do processInput
  else if options.watch?
    options.watch # TODO: watch
  else if options.cli?
    input = options.cli
    do processInput
  else
    process.stdin.on 'data', (data) -> input += data
    process.stdin.on 'end', processInput
    process.stdin.setEncoding 'utf8'
    do process.stdin.resume
