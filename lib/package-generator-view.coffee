path = require 'path'
_ = require 'underscore-plus'
{$, TextEditorView, View} = require 'atom-space-pen-views'
{BufferedProcess} = require 'atom'
fs = require 'fs-plus'

module.exports =
class PackageGeneratorView extends View
  previouslyFocusedElement: null
  mode: null
  customDir: null

  @content: ->
    @div class: 'package-generator', =>
      @div outlet: 'container', =>
        @subview 'nameEditor', new TextEditorView(mini: true)
        @subview 'pathEditor', new TextEditorView(mini: true)
        @div class: 'block', =>
          @div class: 'btn-group', =>
            @button outlet: 'dpBtn', class: 'btn',click: 'setupDefaultPath', 'default path'
            @button outlet: 'npBtn', class: 'btn',click: 'setupCustomPath', 'new path'
        @div class: 'error', outlet: 'error'
        @div class: 'message', outlet: 'message'
        @div outlet: 'output'

  initialize: ->
    @commandSubscription = atom.commands.add 'atom-workspace',
      'package-generator:generate-package': => @attach('package')
      'package-generator:generate-syntax-theme': => @attach('theme')

    @container.on 'blur', => @close()
    @pathEditor.getModel().on 'change', => @updateOutput()
    @nameEditor.getModel().on 'change', => @updateOutput()
    # @pathEditor.on 'dh', => @updateOutput()

    atom.commands.add @element,
      'core:confirm': => @confirm()
      'core:cancel': => @close()

  updateOutput: ->
    @output.text @buildPackagePath()

  # a little helper to make adding/removing btn select css
  # a little less annoying.
  swapBtnSelect: (sel, nosel) ->
    sel.addClass 'selected'
    nosel.removeClass 'selected'
    undefined

  # changes the panel view to use a custom path.
  setupCustomPath: () ->
    @swapBtnSelect @npBtn, @dpBtn
    @pathEditor.setText @getPackagesDirectory()
    @pathEditor.show()

  # reverts the panel to the default view
  setupDefaultPath: () ->
    @swapBtnSelect @dpBtn, @npBtn
    @pathEditor.setText @getPackagesDirectory()
    @pathEditor.hide()

  destroy: ->
    @panel?.destroy()
    @commandSubscription.dispose()

  attach: (@mode) ->
    @panel ?= atom.workspace.addModalPanel(item: this, visible: false)
    @previouslyFocusedElement = $(document.activeElement)
    @panel.show()
    @message.text("Enter #{mode} path")
    if @mode == 'package'
      @setNameText("my-awesome-package")
    else
      @setNameText("my-awesome-syntax")
    @nameEditor.focus()

  close: ->
    return unless @panel.isVisible()
    @panel.hide()
    @previouslyFocusedElement?.focus()

  setNameText: (placeholderName) ->
    nameEditor = @nameEditor.getModel()
    @setupDefaultPath() # setting up the pathEditor
    nameEditor.setText(placeholderName)
    nameEditor.setSelectedBufferRange([[0, 0], [0, placeholderName.length]])

  confirm: ->
    if @validPackagePath()
      @createPackageFiles =>
        packagePath = @buildPackagePath()
        atom.open(pathsToOpen: [packagePath])
        @close()

  buildPackagePath: ->
    # packagePath = @miniEditor.getText().trim()
    # packageName = _.dasherize(path.basename(packagePath))
    # path.join(path.dirname(packagePath), packageName)
    pkgName = _.dasherize @nameEditor.getText().trim()
    pkgPath = @pathEditor.getText().trim()
    path.join(path.dirname(pkgPath), pkgName)

  # retuns the location of either the specified, env variable, or default
  # packages directory
  getPackagesDirectory: ->
    atom.config.get('core.projectHome') or
      process.env.ATOM_REPOS_HOME or
      path.join(fs.getHomeDirectory(), 'github')

  validPackagePath: ->
    if fs.existsSync(@buildPackagePath())
      @error.text("Path already exists at '#{@buildPackagePath()}'")
      @error.show()
      false
    else
      true

  initPackage: (packagePath, callback) ->
    @runCommand(atom.packages.getApmPath(), ['init', "--#{@mode}", "#{packagePath}"], callback)

  linkPackage: (packagePath, callback) ->
    args = ['link']
    args.push('--dev') if atom.config.get('package-generator.createInDevMode')
    args.push packagePath.toString()

    @runCommand(atom.packages.getApmPath(), args, callback)

  isStoredInDotAtom: (packagePath) ->
    packagesPath = path.join(atom.getConfigDirPath(), 'packages', path.sep)
    return true if packagePath.indexOf(packagesPath) is 0

    devPackagesPath = path.join(atom.getConfigDirPath(), 'dev', 'packages', path.sep)
    packagePath.indexOf(devPackagesPath) is 0

  createPackageFiles: (callback) ->
    packagePath = @buildPackagePath()
    packagesDirectory = @getPackagesDirectory()

    if @isStoredInDotAtom(packagePath)
      @initPackage(packagePath, callback)
    else
      @initPackage packagePath, => @linkPackage(packagePath, callback)

  runCommand: (command, args, exit) ->
    new BufferedProcess({command, args, exit})
