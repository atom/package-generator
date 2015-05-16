{
  threadF
  threadL
  injectAtLast
  injectAtFirst
  inject1B4L
  overwrite
  conditional
  catchTrueWith
} = require '../lib/thread'

sum=(a,b,c)->
  return a + b + c

getC = (a,b,c) ->
  c

retFalse = (o) ->
  false

retTrue = (o) ->
  true

cb = (v, c) ->
  if v == 0
    c()
    return true
  false

class Temp
  constructor: (@data=0) ->

  show: (something) ->
    console.log something

  op: () ->
    catchTrueWith @data, (t) =>
      t cb, =>
        @show "this should work"

describe 'Thread', ->

  describe 'threadF', ->
    it 'checking the value with simple sums and argument getters', ->
      total = threadF 0, (t) =>
        t sum, 1, 2
        t sum, 4, 5
        t sum, 13,14
      expect(total).toEqual 39

      total2 = threadF 1, (t) =>
        t getC, null, 5
      expect(total2).toEqual 5

  describe 'threadL', ->
    it 'should inject value at last place in arg', ->
      output = threadL 5, (t) =>
        t getC, 1, 2
        t sum,  1, 2

      expect(output).toEqual 8

  describe 'when using withing an object deifinition', ->
    beforeEach ->
      @obj = new Temp

    it 'show allow using the @ operator ', ->
      spyOn(@obj, 'show')
      expect(@obj.op()).toEqual true
      expect(@obj.show).toHaveBeenCalledWith 'this should work'
      expect(@obj.show.mostRecentCall.args[0]).toEqual 'this should work'


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

describe 'assigners', ->
  beforeEach ->
    @OBJ = class Obj
      constructor: () -> @value = 1

  describe 'overwrite', ->
    it 'should become `cool` when calling overwrite', ->
      obj = new @OBJ
      expect(obj.value).toEqual 1
      overwrite.call(obj, 'cool')
      expect(obj.value).toEqual 'cool'

  describe 'conditional', ->
    describe 'when conditional(true)', ->
      it 'should overwrite the value when the value is equal to true', ->
        obj = new @OBJ
        catchTrue = conditional(true)
        expect(obj.value).toEqual 1
        catchTrue.call(obj, true)
        catchTrue.call(obj, false)
        expect(obj.value).toEqual 1
        expect(obj.cond).toEqual true

      it 'should not overwirte the value with true if it down not see it', ->
        obj = new @OBJ
        catchTrue = conditional(true)
        expect(obj.value).toEqual 1
        catchTrue.call(obj, false)
        catchTrue.call(obj, false)
        expect(obj.value).toEqual 1
        expect(obj.cond).toEqual false
