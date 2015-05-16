class Thread
  constructor: (@value, @options={injector: injectAtFirst,assigner: overwrite}) ->
    @injector = @options.injector.bind @
    @assigner = @options.assigner.bind @

  threader: (fnList...) ->
    fn = fnList.shift()
    args = @injector fnList
    output = fn.apply(undefined, args)
    @assigner output


# assigners
overwrite = (output) ->
  @value = output

conditional = (cond) ->
  calledOnce = false
  (output) ->
    if not calledOnce
      @cond = not cond
      calledOnce = true
    @cond = cond if output is cond



# injectors
injectAtFirst = (fnList) ->
  Array::splice.call fnList, 0, 0, @value
  fnList

injectAtLast = (fnList) ->
  Array::splice.call fnList, fnList.length, 0, @value
  fnList

# inject before last
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
    tf = new Thread value, injector: injectAtLast, assigner: overwrite
    fn(tf.threader.bind(tf))
    tf.value

  thread1B4L: (value, fn) ->
    tf = new Thread value, injector: inject1B4L, assigner: overwrite
    fn(tf.threader.bind(tf))
    tf.value

  catchFalseWith: (value, fn=(t)->) ->
    tf = new Thread value, assigner: conditional(false)
    fn(tf.threader.bind(tf))
    tf.cond

  catchTrueWith: (value, fn=(t)->) ->
    tf = new Thread value, injector: injectAtFirst, assigner: conditional(true)
    fn(tf.threader.bind(tf))
    tf.cond

  Thread
  injectAtFirst
  injectAtLast
  inject1B4L
  overwrite
  conditional
}
