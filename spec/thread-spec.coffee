{
  threadF
  threadL
  injectAtLast
  injectAtFirst
  inject1B4L
} = require '../lib/thread'

sum=(a,b,c)->
  return a + b + c

getC = (a,b,c) ->
  c

describe 'Thread', ->

  describe 'threadF', ->
    it 'checking the value with simple sums and argument getters', ->
      total = threadF 0, (t) ->
        t sum, 1, 2
        t sum, 4, 5
        t sum, 13,14
      expect(total).toEqual 39

      total2 = threadF 1, (t) ->
        t getC, null, 5
      expect(total2).toEqual 5

  describe 'threadL', ->
    it 'should inject value at last place in arg', ->
      output = threadL 5, (t) ->
        t getC, 1, 2
        t sum,  1, 2

      expect(output).toEqual 8

describe 'injectors', ->
  beforeEach ->
    @OBJ = class Obj
      constructor: () -> @value = 1

  describe 'injectAtFirst', ->
    it 'should insert 1 at the first place of [2 3 4]', ->
      finalArgList = injectAtFirst.call(new @OBJ,[2,3,4])
      expect(finalArgList).toEqual [1,2,3,4]

  describe 'injectAtLast', ->
    it 'should insert 1 at the last place of [2 3 4]', ->
      finalArgList = injectAtLast.call(new @OBJ,[2,3,4])
      expect(finalArgList).toEqual [2,3,4,1]

  describe 'inject1B4L', ->
    it 'should insert 1 at the second to last place of [2 3 4]', ->
      finalArgList = inject1B4L.call(new @OBJ,[2,3,4])
      expect(finalArgList).toEqual [2,3,1,4]
