path = require 'path'
_ = require 'underscore-plus'
{$, TextEditorView, View} = require 'atom-space-pen-views'
{BufferedProcess} = require 'atom'
fs = require 'fs-plus'
{validPermission} = require './permission'
{isStoredInDotAtom} = require "./validation"

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
            @button outlet: 'dpBtn', class: 'btn', click: 'setupDefaultPath', 'default path'
            @button outlet: 'npBtn', class: 'btn', click: 'setupCustomPath', 'new path'
        @div class: 'error', outlet: 'error'
        @div class: 'message', outlet: 'message'
        @progress max: 100, value: 0, class: 'progress', outlet: 'progress'

  initialize: ->
    @commandSubscription = atom.commands.add 'atom-workspace',
      'package-generator:generate-package': => @attach('package')
      'package-generator:generate-syntax-theme': => @attach('theme')

    @container.on 'blur', => @close()

    atom.commands.add @element,
      'core:confirm': => @confirm()
      'core:cancel': => @close()

  resetPanel: ->
    @setupDefaultPath()
    @progress.attr 'value', '0'
    @error.text('')
    @message.text('')

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
    @setupDefaultPath()
    @nameEditor.focus()

  close: ->
    return unless @panel.isVisible()
    @resetPanel()
    @panel.hide()
    @previouslyFocusedElement?.focus()

  setNameText: (placeholderName) ->
    nameEditor = @nameEditor.getModel()
    nameEditor.setText(placeholderName)
    nameEditor.setSelectedBufferRange([[0, 0], [0, placeholderName.length]])

  confirm: ->
    finalPackageLocation = @buildPackagePath()
    @progress.show()
    @progress.attr 'value', '33'
    console.log finalPackageLocation
    if @validPackagePath(finalPackageLocation)
      @progress.attr 'value', '66'
      @createPackageFiles finalPackageLocation, =>
        @progress.attr 'value', '100'
        atom.open(pathsToOpen: [finalPackageLocation])
        @close()
        atom.notifications.addSuccess("#{@pkgName} was created!")

  sanitizeNameInput: (textField) ->
    _.dasherize(textField.getText()).trim()

  buildPackagePath: ->
    @pkgName = @sanitizeNameInput @nameEditor
    pkgPath = @pathEditor.getText().trim()
    path.join(pkgPath, @pkgName)

  getPackagesDirectory: ->
    atom.config.get('core.projectHome') or
      process.env.ATOM_REPOS_HOME or
      path.join(fs.getHomeDirectory(), 'github')

  showError: (text) ->
    @error.text text
    @error.show()

  validPackagePath: (finalPackageLocation) ->
    if not @makeSureDirectoryExists finalPackageLocation
      @close()
      atom.notifications.addError("#{@pkgName} was not created successfully...")
      return false
    if @nameEditor.length is 0
      @showError "You never input a group '#{finalPackageLocation}'"
      return false
    else if fs.existsSync(finalPackageLocation)
      @showError "Path already exists at '#{finalPackageLocation}'"
      return false
    else if not validPermission(finalPackageLocation)
      @showError "You do not have the right to save at #{finalPackageLocation}"
      return false

    true # yay! valid package

  makeSureDirectoryExists: (saveLocation) ->
    dir = path.dirname saveLocation
    if not fs.existsSync dir
      create = confirm "#{dir} does not exist. Would you like to make a new one?", "Folder doesn't exist"
      if create
        fs.mkdirSync dir
        return true
      else
        return false

    return true

  initPackage: (saveLocation, callback) ->
    @runCommand(atom.packages.getApmPath(), ['init', "--#{@mode}", "#{saveLocation}"], callback)

  linkPackage: (packagePath, callback) ->
    args = ['link']
    args.push('--dev') if atom.config.get('package-generator.createInDevMode')
    args.push packagePath.toString()

    @runCommand(atom.packages.getApmPath(), args, callback)

  createPackageFiles: (saveLocation, callback) ->
    if isStoredInDotAtom(saveLocation)
      @initPackage(saveLocation, callback)
    else
      @initPackage saveLocation, => @linkPackage(saveLocation, callback)

  runCommand: (command, args, exit) ->
    new BufferedProcess({command, args, exit})
