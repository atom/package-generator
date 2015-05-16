class Thread
  constructor: (@value, @options={injecter: injectAtFirst}) ->
    @injecter = @options.injecter.bind @

  threader: (fnList...) ->
    fn = fnList.shift()
    args = @injecter fnList
    @value = fn.apply(undefined, args)

# data flow

# injectors
injectAtFirst = (fnList) ->
  Array::splice.call fnList, 0, 0, @value
  fnList

injectAtLast = (fnList) ->
  Array::splice.call fnList, fnList.length, 0, @value
  fnList

inject1B4L = (fnList) ->
  if fnList.length is 1
    fnList[0] = @value
    return fnList

  Array::splice.call fnList, fnList.length-1, 0, @value
  fnList


module.exports = {
  threadF: (value, fn) ->
    tf = new Thread value
    fn(tf.threader.bind(tf))
    tf.value

  threadL: (value, fn) ->
    tf = new Thread value, injecter: injectAtLast
    fn(tf.threader.bind(tf))
    tf.value

  thread1B4L: (value, fn) ->
    tf = new Thread value, injecter: inject1B4L
    fn(tf.threader.bind(tf))
    tf.value

  Thread
  injectAtFirst
  injectAtLast
  inject1B4L
}
