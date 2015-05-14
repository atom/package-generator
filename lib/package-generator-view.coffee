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

  initialize: ->
    @commandSubscription = atom.commands.add 'atom-workspace',
      'package-generator:generate-package': => @attach('package')
      'package-generator:generate-syntax-theme': => @attach('theme')

    @container.on 'blur', => @close()

    atom.commands.add @element,
      'core:confirm': => @confirm()
      'core:cancel': => @close()

  swapBtnSelect: (sel, nosel) ->
    sel.addClass 'selected'
    nosel.removeClass 'selected'
    undefined

  # changes the panel view to use a custom path.
  setupCustomPath: () ->
    @swapBtnSelect @npBtn, @dpBtn
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
    @panel.hide()
    @previouslyFocusedElement?.focus()

  setNameText: (placeholderName) ->
    nameEditor = @nameEditor.getModel()
    nameEditor.setText(placeholderName)
    nameEditor.setSelectedBufferRange([[0, 0], [0, placeholderName.length]])

  confirm: ->
    finalPackageLocation = @buildPackagePath()
    if @validPackagePath(finalPackageLocation)
      @createPackageFiles finalPackageLocation, =>
        atom.open(pathsToOpen: [finalPackageLocation])
        @close()

  buildPackagePath: ->
    pkgName = _.dasherize @nameEditor.getText().trim()
    pkgPath = @pathEditor.getText().trim()
    path.join(path.dirname(pkgPath), pkgName)

  getPackagesDirectory: ->
    atom.config.get('core.projectHome') or
      process.env.ATOM_REPOS_HOME or
      path.join(fs.getHomeDirectory(), 'github')

  userIsOwner: (stats) ->
    owner = (process.getuid() is stats.uid)
    owner && (stats.mode & 0o00200)

  usersGroupCanWrite: (stats) ->
    inGroup = (process.getgid() is stats.gid)
    inGroup && (stats.mode & 0o00020)

  anyoneCanWrite: (stats) ->
    (stats.mode & 0o00002)

  validPermission: (saveLocation) ->
    stats = fs.statSync path.dirname(saveLocation)
    if @userIsOwner(stats) or
       @usersGroupCanWrite(stats) or
       @anyoneCanWrite(stats)
      return true
    else
      @error.text("You do not have the required privilege to save in #{path.dirname(saveLocation)}.")
      @error.show()
      false

  alreadyPackage: (saveLocation) ->
    if fs.existsSync(saveLocation)
      @error.text("Path already exists at '#{saveLocation}'")
      @error.show()
      true
    else
      false

  validPackagePath: (finalPackageLocation) ->
    return false if @alreadyPackage finalPackageLocation
    return false if not @validPermission finalPackageLocation
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

  createPackageFiles: (saveLocation, callback) ->
    packagePath = @buildPackagePath()
    packagesDirectory = @getPackagesDirectory()

    if @isStoredInDotAtom(packagePath)
      @initPackage(packagePath, callback)
    else
      @initPackage packagePath, => @linkPackage(packagePath, callback)

  runCommand: (command, args, exit) ->
    new BufferedProcess({command, args, exit})
