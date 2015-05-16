{
  threadF
  threadL
  injectAtLast
  injectAtFirst
} = require '../lib/thread'

sum=(a,b,c)->
  return a + b + c

getC = (a,b,c) ->
  c

describe 'Thread', ->

  describe 'threadF', ->
    it 'checking the total', ->
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
  describe 'At the first location', ->
    it 'should insert 1 at the first place of [2 3 4]', ->
      class Obj
        constructor: () -> @value = 1

      finalArgList = injectAtFirst.call(new Obj,[2,3,4])
      expect(finalArgList).toEqual [1,2,3,4]
