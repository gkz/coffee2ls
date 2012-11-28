suite 'LiveScript specific', ->

  test 'LiveScript reserved identifiers', ->
    match = 10
    match = 11
    eq 11, match

  test 'LiveScript reserved as properties', ->
    obj =
      match: 54
      xor: 12

    eq 54, obj.match
    eq 12, obj.xor
