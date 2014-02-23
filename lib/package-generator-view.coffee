_ = require 'underscore-plus'
{$, BufferedNodeProcess, EditorView, fs, View} = require 'atom'
path = require 'path'

module.exports =
class PackageGeneratorView extends View
  previouslyFocusedElement: null
  mode: null

  @content: ->
    @div class: 'package-generator overlay from-top', =>
      @subview 'miniEditor', new EditorView(mini: true)
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
    atom.workspaceView.append(this)
    @setPathText("#{mode}-name")
    @miniEditor.focus()

  setPathText: (placeholderName) ->
    {editor} = @miniEditor
    packagesDirectory = @getPackagesDirectory()
    editor.setText(path.join(packagesDirectory, placeholderName))
    pathLength = editor.getText().length
    editor.setSelectedBufferRange([[0, pathLength - placeholderName.length], [0, pathLength]])

  detach: ->
    return unless @hasParent()
    @previouslyFocusedElement?.focus()
    super

  confirm: ->
    if @validPackagePath()
      @createPackageFiles =>
        packagePath = @getPackagePath()
        atom.open(pathsToOpen: [packagePath])
        @detach()

  getPackagePath: ->
    packagePath = @miniEditor.getText()
    packageName = _.dasherize(path.basename(packagePath))
    path.join(path.dirname(packagePath), packageName)

  getPackagesDirectory: ->
    _.last(atom.packages.getPackageDirPaths())

  validPackagePath: ->
    if fs.existsSync(@getPackagePath())
      @error.text("Path already exists at '#{@getPackagePath()}'")
      @error.show()
      false
    else
      true

  initPackage: (packagePath, callback) ->
    @runCommand(atom.packages.getApmPath(), ['init', "--#{@mode}", "#{packagePath}"], callback)

  linkPackage: (packagePath, callback) ->
    @runCommand(atom.packages.getApmPath(), ['link', "#{packagePath}"], callback)

  createPackageFiles: (callback) ->
    packagePath = @getPackagePath()
    packagesDirectory = @getPackagesDirectory()

    if packagePath.indexOf(path.join(packagesDirectory, path.sep)) is 0
      @initPackage(packagePath, callback)
    else
      @initPackage packagePath, => @linkPackage(packagePath, callback)

  runCommand: (command, args, exit) ->
    new BufferedNodeProcess({command, args, exit})
