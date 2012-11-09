suite 'strings', ->
  test "block strings", ->
    r = '''
        a
        b
        '''
    eq 'a\nb', r
    eq '', ''''''
    eq ' a', ''' a'''
  test "interp block strings", ->
    r = """
        a
        b
        """
    eq 'a\nb', r
    eq '', """"""
    eq ' a', """ a"""
    eq '', """
    """
