{_, $, BufferedNodeProcess, Editor, fs, View} = require 'atom'
path = require 'path'

module.exports =
class PackageGeneratorView extends View
  previouslyFocusedElement: null
  mode: null

  @content: ->
    @div class: 'package-generator overlay from-top', =>
      @subview 'miniEditor', new Editor(mini: true)
      @div class: 'error', outlet: 'error'
      @div class: 'message', outlet: 'message'

  initialize: ->
    atom.workspaceView.command "package-generator:generate-package", => @attach('package')
    atom.workspaceView.command "package-generator:generate-syntax-theme", => @attach('theme')
    @miniEditor.hiddenInput.on 'focusout', => @detach()
    @on 'core:confirm', => @confirm()
    @on 'core:cancel', => @detach()

  attach: (@mode) ->
    @previouslyFocusedElement = $(':focus')
    @message.text("Enter #{mode} path")
    placeholderName = "#{mode}-name"
    packagesDirectory = _.last(atom.packages.getPackageDirPaths())
    @miniEditor.setText(path.join(packagesDirectory, placeholderName))
    pathLength = @miniEditor.getText().length
    @miniEditor.setSelectedBufferRange([[0, pathLength - placeholderName.length], [0, pathLength]])

    atom.workspaceView.append(this)
    @miniEditor.focus()

  detach: ->
    return unless @hasParent()
    @previouslyFocusedElement?.focus()
    super

  confirm: ->
    if @validPackagePath()
      @createPackageFiles =>
        packagePath = @getPackagePath()
        atom.packages.enablePackage(path.basename(packagePath))
        atom.open(pathsToOpen: [packagePath])
        @detach()

  getPackagePath: ->
    packagePath = @miniEditor.getText()
    packageName = _.dasherize(path.basename(packagePath))
    path.join(path.dirname(packagePath), packageName)

  validPackagePath: ->
    if fs.existsSync(@getPackagePath())
      @error.text("Path already exists at '#{@getPackagePath()}'")
      @error.show()
      false
    else
      true

  createPackageFiles: (callback) ->
    @runCommand(atom.packages.getApmPath(), ['init', "--#{@mode}", "#{@getPackagePath()}"], callback)

  runCommand: (command, args, exit) ->
    new BufferedNodeProcess({command, args, exit})
