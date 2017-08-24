path = require 'path'
_ = require 'underscore-plus'
{TextEditor, BufferedProcess, CompositeDisposable, Disposable} = require 'atom'
fs = require 'fs-plus'

module.exports =
class PackageGeneratorView
  previouslyFocusedElement: null
  mode: null

  constructor: ->
    @disposables = new CompositeDisposable

    @element = document.createElement('div')
    @element.classList.add('package-generator')

    @miniEditor = new TextEditor({mini: true})
    @element.appendChild(@miniEditor.element)

    @error = document.createElement('div')
    @error.classList.add('error')
    @element.appendChild(@error)

    @message = document.createElement('div')
    @message.classList.add('message')
    @element.appendChild(@message)

    @disposables.add atom.commands.add 'atom-workspace',
      'package-generator:generate-package': => @attach('package')
      'package-generator:generate-syntax-theme': => @attach('theme')

    blurHandler = => @close()
    @miniEditor.element.addEventListener('blur', blurHandler)
    @disposables.add(new Disposable(=> @miniEditor.element.removeEventListener('blur', blurHandler)))
    @disposables.add atom.commands.add @element,
      'core:confirm': => @confirm()
      'core:cancel': => @close()

  destroy: ->
    @panel?.destroy()
    @disposables.dispose()

  attach: (@mode) ->
    @panel ?= atom.workspace.addModalPanel({item: this, visible: false})
    @previouslyFocusedElement = document.activeElement
    @panel.show()
    @message.textContent = "Enter #{@mode} path"
    if @isInPackageMode()
      @setPathText("my-package")
    else
      @setPathText("my-theme-syntax", [0, 8])
    @miniEditor.element.focus()

  setPathText: (placeholderName, rangeToSelect) ->
    rangeToSelect ?= [0, placeholderName.length]
    packagesDirectory = @getPackagesDirectory()
    @miniEditor.setText(path.join(packagesDirectory, placeholderName))
    pathLength = @miniEditor.getText().length
    endOfDirectoryIndex = pathLength - placeholderName.length
    @miniEditor.setSelectedBufferRange([[0, endOfDirectoryIndex + rangeToSelect[0]], [0, endOfDirectoryIndex + rangeToSelect[1]]])

  close: ->
    return unless @panel.isVisible()
    @panel.hide()
    @previouslyFocusedElement?.focus()

  confirm: ->
    if @validPackagePath()
      @createPackageFiles =>
        packagePath = @getPackagePath()
        atom.open(pathsToOpen: [packagePath])
        @close()

  getPackagePath: ->
    packagePath = fs.normalize(@miniEditor.getText().trim())
    packageName = _.dasherize(path.basename(packagePath))
    path.join(path.dirname(packagePath), packageName)

  getPackagesDirectory: ->
    process.env.ATOM_REPOS_HOME or
      atom.config.get('core.projectHome') or
      path.join(fs.getHomeDirectory(), 'github')

  validPackagePath: ->
    if fs.existsSync(@getPackagePath())
      @error.textContent = "Path already exists at '#{@getPackagePath()}'"
      @error.style.display = 'block'
      false
    else
      true

  getInitOptions: (packagePath) ->
    options = ["--#{@mode}", packagePath]
    if @isInPackageMode()
      [options..., '--syntax', atom.config.get('package-generator.packageSyntax')]
    else
      options

  initPackage: (packagePath, callback) ->
    command = ['init', @getInitOptions(packagePath)...]
    @runCommand(atom.packages.getApmPath(), command, callback)

  linkPackage: (packagePath, callback) ->
    args = ['link']
    args.push('--dev') if atom.config.get('package-generator.createInDevMode')
    args.push packagePath.toString()

    @runCommand(atom.packages.getApmPath(), args, callback)

  isInPackageMode: ->
    @mode is 'package'

  isStoredInDotAtom: (packagePath) ->
    packagesPath = path.join(atom.getConfigDirPath(), 'packages', path.sep)
    return true if packagePath.indexOf(packagesPath) is 0

    devPackagesPath = path.join(atom.getConfigDirPath(), 'dev', 'packages', path.sep)
    packagePath.indexOf(devPackagesPath) is 0

  createPackageFiles: (callback) ->
    packagePath = @getPackagePath()

    if @isStoredInDotAtom(packagePath)
      @initPackage(packagePath, callback)
    else
      @initPackage packagePath, => @linkPackage(packagePath, callback)

  runCommand: (command, args, exit) ->
    new BufferedProcess({command, args, exit})
