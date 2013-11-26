temp = require 'temp'
path = require 'path'
{fs, WorkspaceView} = require 'atom'

describe 'Package Generator', ->

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.workspaceView.openSync('sample.js')
    atom.packages.activatePackage("package-generator")

  describe "when package-generator:generate-package is triggered", ->
    it "displays a miniEditor", ->
      atom.workspaceView.trigger("package-generator:generate-package")
      packageGeneratorView = atom.workspaceView.find(".package-generator")
      expect(packageGeneratorView).toExist()

  describe "when core:cancel is triggered", ->
    it "detaches from the DOM and focuses the the previously focused element", ->
      atom.workspaceView.attachToDom()
      atom.workspaceView.trigger("package-generator:generate-package")
      packageGeneratorView = atom.workspaceView.find(".package-generator").view()
      expect(packageGeneratorView.miniEditor.isFocused).toBeTruthy()
      expect(atom.workspaceView.getActiveView().isFocused).toBeFalsy()

      packageGeneratorView.trigger("core:cancel")
      expect(packageGeneratorView.hasParent()).toBeFalsy()
      expect(atom.workspaceView.getActiveView().isFocused).toBeTruthy()

  describe "when a package is generated", ->
    [packageName, packagePath, packageRoot] = []

    beforeEach ->
      spyOn(atom, "open")

      packageRoot = temp.mkdirSync('atom')
      packageName = "sweet-package-dude"
      packagePath = path.join(packageRoot, packageName)
      fs.removeSync(packageRoot)

    afterEach ->
      fs.removeSync(packageRoot)

    it "forces the package's name to be lowercase with dashes", ->
      packageName = "CamelCaseIsForTheBirds"
      packagePath = path.join(path.dirname(packagePath), packageName)
      atom.workspaceView.trigger("package-generator:generate-package")
      packageGeneratorView = atom.workspaceView.find(".package-generator").view()
      packageGeneratorView.miniEditor.setText(packagePath)
      apmExecute = spyOn(packageGeneratorView, 'runCommand')
      packageGeneratorView.trigger "core:confirm"

      expect(apmExecute).toHaveBeenCalled()
      expect(apmExecute.mostRecentCall.args[0]).toBe atom.packages.getApmPath()
      expect(apmExecute.mostRecentCall.args[1]).toEqual ['init', '--package', "#{path.join(path.dirname(packagePath), "camel-case-is-for-the-birds")}"]

    describe 'when creating a package', ->
      beforeEach -> atom.workspaceView.trigger("package-generator:generate-package")

      it "calls `apm init`", ->
        packageGeneratorView = atom.workspaceView.find(".package-generator").view()
        expect(packageGeneratorView.hasParent()).toBeTruthy()
        packageGeneratorView.miniEditor.setText(packagePath)
        apmExecute = spyOn(packageGeneratorView, 'runCommand')
        enablePackage = spyOn(atom.packages, 'enablePackage')
        packageGeneratorView.trigger "core:confirm"

        expect(apmExecute).toHaveBeenCalled()
        expect(apmExecute.mostRecentCall.args[0]).toBe atom.packages.getApmPath()
        expect(apmExecute.mostRecentCall.args[1]).toEqual ['init', '--package', "#{packagePath}"]

        apmExecute.mostRecentCall.args[2]()

        expect(enablePackage).toHaveBeenCalled()
        expect(enablePackage.mostRecentCall.args[0]).toBe packageName

    describe 'when creating a theme', ->
      beforeEach -> atom.workspaceView.trigger("package-generator:generate-syntax-theme")

      it "calls `apm init`", ->
        packageGeneratorView = atom.workspaceView.find(".package-generator").view()
        expect(packageGeneratorView.hasParent()).toBeTruthy()
        packageGeneratorView.miniEditor.setText(packagePath)
        apmExecute = spyOn(packageGeneratorView, 'runCommand')
        enablePackage = spyOn(atom.packages, 'enablePackage')
        packageGeneratorView.trigger "core:confirm"

        expect(apmExecute).toHaveBeenCalled()
        expect(apmExecute.mostRecentCall.args[0]).toBe atom.packages.getApmPath()
        expect(apmExecute.mostRecentCall.args[1]).toEqual ['init', '--theme', "#{packagePath}"]

        apmExecute.mostRecentCall.args[2]()

        expect(enablePackage).toHaveBeenCalled()
        expect(enablePackage.mostRecentCall.args[0]).toBe packageName

    it "displays an error when the package path already exists", ->
      atom.workspaceView.attachToDom()
      fs.makeTreeSync(packagePath)
      atom.workspaceView.trigger("package-generator:generate-package")
      packageGeneratorView = atom.workspaceView.find(".package-generator").view()

      expect(packageGeneratorView.hasParent()).toBeTruthy()
      expect(packageGeneratorView.error).not.toBeVisible()
      packageGeneratorView.miniEditor.setText(packagePath)
      packageGeneratorView.trigger "core:confirm"
      expect(packageGeneratorView.hasParent()).toBeTruthy()
      expect(packageGeneratorView.error).toBeVisible()

    it "opens the package", ->
      atom.workspaceView.trigger("package-generator:generate-package")
      packageGeneratorView = atom.workspaceView.find(".package-generator").view()
      packageGeneratorView.miniEditor.setText(packagePath)
      apmExecute = spyOn(packageGeneratorView, 'runCommand')
      loadPackage = spyOn(atom.packages, 'loadPackage')
      packageGeneratorView.trigger "core:confirm"
      apmExecute.mostRecentCall.args[2]()

      expect(atom.open).toHaveBeenCalledWith(pathsToOpen: [packagePath])
