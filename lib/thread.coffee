injectAtFirst = (fnList) ->
  Array::splice.call fnList, 0, 0, @value
  fnList

injectAtLast = (fnList) ->
  Array::splice.call fnList, fnList.length, 0, @value
  fnList


class Thread
  constructor: (@value, @options={injecter: injectAtFirst}) ->
    @injecter = @options.injecter.bind @

  threader: (fnList...) ->
    fn = fnList.shift()
    args = @injecter fnList
    @value = fn.apply(undefined, args)


module.exports = {
  threadF: (value, fn) ->
    tf = new Thread value
    fn(tf.threader.bind(tf))
    tf.value

  threadL: (value, fn) ->
    tf = new Thread value, injecter: injectAtLast
    fn(tf.threader.bind(tf))
    tf.value

  Thread
  injectAtFirst
  injectAtLast
}
