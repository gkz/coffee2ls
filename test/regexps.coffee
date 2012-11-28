suite 'Regular Expressions', ->

  test 'differentiate regexps from division', ->
    a = -> 0
    a.valueOf = -> 1
    b = i = 1

    eq 1, a / b
    eq 1, a/ b
    eq 1, a/b
    eq 1, a / b / i
    eq 1, a/ b / i
    eq 1, a / b/ i
    eq 1, a / b /i
    eq 1, a/b / i
    eq 1, a/ b/ i
    eq 1, a/ b /i
    eq 1, a/b/ i
    eq 1, a/ b/i
    eq 1, a/b/i
    eq 1, b /= a
    eq 1, b/=a/i
    eq 1, b /=a/i
    eq 1, b /=a
    i=/a/i
    a[/a/]

    eq 0, a /b/i
    eq 0, a(/b/i)
    eq 0, a /b /i

  # FAIL Failing as LiveScript can't handle this
  ###
  test 'regexps can start with spaces and = when unambiguous', ->
    a = -> 0
    eq 0, a(/ b/i)
    eq 0, a(/= b/i)
    eq 0, a a[/ b/i]
    eq 0, a(/ /)
    eq 1, +/ /.test ' '
    eq 1, +/=/.test '='
  ###

  test 'regexps can be empty', ->
    ok //.test ''

  test 'regexps with spaces', ->
    ok /hi there/.test 'hi there'

  test 'regexps with interpolation', ->
    x = 'hi'
    ok ///#{x}!///.test 'hi!'
