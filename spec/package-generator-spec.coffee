RootView = require 'root-view'
fsUtils = require 'fs-utils'
path = require 'path'

describe 'Package Generator', ->
  [packageGenerator] = []

  beforeEach ->
    window.rootView = new RootView
    rootView.open('sample.js')
    atom.activatePackage("package-generator")

  describe "when package-generator:generate is triggered", ->
    it "displays a miniEditor", ->
      rootView.trigger("package-generator:generate")
      packageGeneratorView = rootView.find(".package-generator")
      expect(packageGeneratorView).toExist()

  describe "when core:cancel is triggered", ->
    it "detaches from the DOM and focuses the the previously focused element", ->
      rootView.attachToDom()
      rootView.trigger("package-generator:generate")
      packageGeneratorView = rootView.find(".package-generator").view()
      expect(packageGeneratorView.miniEditor.isFocused).toBeTruthy()
      expect(rootView.getActiveView().isFocused).toBeFalsy()

      packageGeneratorView.trigger("core:cancel")
      expect(packageGeneratorView.hasParent()).toBeFalsy()
      expect(rootView.getActiveView().isFocused).toBeTruthy()

  describe "when a package is generated", ->
    [packageName, packagePath] = []

    beforeEach ->
      spyOn(atom, "open")

      packageName = "sweet-package-dude"
      packagePath = "/tmp/atom-packages/#{packageName}"
      fsUtils.remove(packagePath) if fsUtils.exists(packagePath)

    afterEach ->
      fsUtils.remove(packagePath) if fsUtils.exists(packagePath)

    it "forces the package's name to be lowercase with dashes", ->
      packageName = "CamelCaseIsForTheBirds"
      packagePath = path.join(path.dirname(packagePath), packageName)
      rootView.trigger("package-generator:generate")
      packageGeneratorView = rootView.find(".package-generator").view()
      packageGeneratorView.miniEditor.setText(packagePath)
      packageGeneratorView.trigger "core:confirm"

      expect(packagePath).not.toExistOnDisk()
      expect(path.join(path.dirname(packagePath), "camel-case-is-for-the-birds")).toExistOnDisk()

    it "calls `apm init`", ->
      rootView.trigger("package-generator:generate")
      packageGeneratorView = rootView.find(".package-generator").view()
      expect(packageGeneratorView.hasParent()).toBeTruthy()
      packageGeneratorView.miniEditor.setText(packagePath)
      apmExecute = spyOn(packageGeneratorView, 'runCommand')
      packageGeneratorView.trigger "core:confirm"

      expect(apmExecute).toHaveBeenCalled()
      expect(apmExecute.mostRecentCall.args[0]).toBe 'apm'
      expect(apmExecute.mostRecentCall.args[1]).toEqual ['init', "-p #{packagePath}"]

    it "displays an error when the package path already exists", ->
      rootView.attachToDom()
      fsUtils.makeTree(packagePath)
      rootView.trigger("package-generator:generate")
      packageGeneratorView = rootView.find(".package-generator").view()

      expect(packageGeneratorView.hasParent()).toBeTruthy()
      expect(packageGeneratorView.error).not.toBeVisible()
      packageGeneratorView.miniEditor.setText(packagePath)
      packageGeneratorView.trigger "core:confirm"
      expect(packageGeneratorView.hasParent()).toBeTruthy()
      expect(packageGeneratorView.error).toBeVisible()

    it "opens the package", ->
      rootView.trigger("package-generator:generate")
      packageGeneratorView = rootView.find(".package-generator").view()
      packageGeneratorView.miniEditor.setText(packagePath)
      apmExecute = spyOn(packageGeneratorView, 'runCommand')
      packageGeneratorView.trigger "core:confirm"
      apmExecute.mostRecentCall.args[2]()

      expect(atom.open).toHaveBeenCalledWith(pathsToOpen: [packagePath])
