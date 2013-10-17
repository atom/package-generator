temp = require 'temp'
path = require 'path'
{fs, RootView} = require 'atom'

describe 'Package Generator', ->

  beforeEach ->
    window.rootView = new RootView
    rootView.openSync('sample.js')
    atom.activatePackage("package-generator")

  describe "when package-generator:generate-package is triggered", ->
    it "displays a miniEditor", ->
      rootView.trigger("package-generator:generate-package")
      packageGeneratorView = rootView.find(".package-generator")
      expect(packageGeneratorView).toExist()

  describe "when core:cancel is triggered", ->
    it "detaches from the DOM and focuses the the previously focused element", ->
      rootView.attachToDom()
      rootView.trigger("package-generator:generate-package")
      packageGeneratorView = rootView.find(".package-generator").view()
      expect(packageGeneratorView.miniEditor.isFocused).toBeTruthy()
      expect(rootView.getActiveView().isFocused).toBeFalsy()

      packageGeneratorView.trigger("core:cancel")
      expect(packageGeneratorView.hasParent()).toBeFalsy()
      expect(rootView.getActiveView().isFocused).toBeTruthy()

  describe "when a package is generated", ->
    [packageName, packagePath, packageRoot] = []

    beforeEach ->
      spyOn(atom, "open")

      packageRoot = temp.mkdirSync('atom')
      packageName = "sweet-package-dude"
      packagePath = path.join(packageRoot, packageName)
      fs.remove(packageRoot) if fs.exists(packageRoot)

    afterEach ->
      fs.remove(packageRoot) if fs.exists(packageRoot)

    it "forces the package's name to be lowercase with dashes", ->
      packageName = "CamelCaseIsForTheBirds"
      packagePath = path.join(path.dirname(packagePath), packageName)
      rootView.trigger("package-generator:generate-package")
      packageGeneratorView = rootView.find(".package-generator").view()
      packageGeneratorView.miniEditor.setText(packagePath)
      apmExecute = spyOn(packageGeneratorView, 'runCommand')
      packageGeneratorView.trigger "core:confirm"

      expect(apmExecute).toHaveBeenCalled()
      expect(apmExecute.mostRecentCall.args[0]).toBe 'apm'
      expect(apmExecute.mostRecentCall.args[1]).toEqual ['init', '--package', "#{path.join(path.dirname(packagePath), "camel-case-is-for-the-birds")}"]

    describe 'when creating a package', ->
      beforeEach -> rootView.trigger("package-generator:generate-package")

      it "calls `apm init`", ->
        packageGeneratorView = rootView.find(".package-generator").view()
        expect(packageGeneratorView.hasParent()).toBeTruthy()
        packageGeneratorView.miniEditor.setText(packagePath)
        apmExecute = spyOn(packageGeneratorView, 'runCommand')
        loadPackage = spyOn(atom.packages, 'loadPackage')
        packageGeneratorView.trigger "core:confirm"

        expect(apmExecute).toHaveBeenCalled()
        expect(apmExecute.mostRecentCall.args[0]).toBe 'apm'
        expect(apmExecute.mostRecentCall.args[1]).toEqual ['init', '--package', "#{packagePath}"]

        apmExecute.mostRecentCall.args[2]()

        expect(loadPackage).toHaveBeenCalled()
        expect(loadPackage.mostRecentCall.args[0]).toBe packageName

    describe 'when creating a theme', ->
      beforeEach -> rootView.trigger("package-generator:generate-syntax-theme")

      it "calls `apm init`", ->
        packageGeneratorView = rootView.find(".package-generator").view()
        expect(packageGeneratorView.hasParent()).toBeTruthy()
        packageGeneratorView.miniEditor.setText(packagePath)
        apmExecute = spyOn(packageGeneratorView, 'runCommand')
        loadPackage = spyOn(atom.packages, 'loadPackage')
        packageGeneratorView.trigger "core:confirm"

        expect(apmExecute).toHaveBeenCalled()
        expect(apmExecute.mostRecentCall.args[0]).toBe 'apm'
        expect(apmExecute.mostRecentCall.args[1]).toEqual ['init', '--theme', "#{packagePath}"]

        apmExecute.mostRecentCall.args[2]()

        expect(loadPackage).toHaveBeenCalled()
        expect(loadPackage.mostRecentCall.args[0]).toBe packageName

    it "displays an error when the package path already exists", ->
      rootView.attachToDom()
      fs.makeTree(packagePath)
      rootView.trigger("package-generator:generate-package")
      packageGeneratorView = rootView.find(".package-generator").view()

      expect(packageGeneratorView.hasParent()).toBeTruthy()
      expect(packageGeneratorView.error).not.toBeVisible()
      packageGeneratorView.miniEditor.setText(packagePath)
      packageGeneratorView.trigger "core:confirm"
      expect(packageGeneratorView.hasParent()).toBeTruthy()
      expect(packageGeneratorView.error).toBeVisible()

    it "opens the package", ->
      rootView.trigger("package-generator:generate-package")
      packageGeneratorView = rootView.find(".package-generator").view()
      packageGeneratorView.miniEditor.setText(packagePath)
      apmExecute = spyOn(packageGeneratorView, 'runCommand')
      loadPackage = spyOn(atom.packages, 'loadPackage')
      packageGeneratorView.trigger "core:confirm"
      apmExecute.mostRecentCall.args[2]()

      expect(atom.open).toHaveBeenCalledWith(pathsToOpen: [packagePath])
