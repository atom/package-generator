path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
{WorkspaceView} = require 'atom'

describe 'Package Generator', ->
  [activationPromise] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.workspaceView.openSync('sample.js')
    activationPromise = atom.packages.activatePackage("package-generator")

  describe "when package-generator:generate-package is triggered", ->
    it "displays a miniEditor with the correct text and selection", ->
      atom.workspaceView.trigger("package-generator:generate-package")

      waitsForPromise ->
        activationPromise

      runs ->
        packageGeneratorView = atom.workspaceView.find(".package-generator").view()
        packageName = packageGeneratorView.miniEditor.editor.getSelectedText()
        expect(packageName).toEqual 'my-package'

        fullPath = packageGeneratorView.miniEditor.editor.getText()
        base = atom.config.get 'core.projectHome'
        expect(fullPath).toEqual path.join(base, 'my-package')

  describe "when package-generator:generate-theme is triggered", ->
    it "displays a miniEditor with correct text and selection", ->
      atom.workspaceView.trigger("package-generator:generate-syntax-theme")

      waitsForPromise ->
        activationPromise

      runs ->
        packageGeneratorView = atom.workspaceView.find(".package-generator").view()
        themeName = packageGeneratorView.miniEditor.editor.getSelectedText()
        expect(themeName).toEqual 'my-theme'

        fullPath = packageGeneratorView.miniEditor.editor.getText()
        base = atom.config.get 'core.projectHome'
        expect(fullPath).toEqual path.join(base, 'my-theme-syntax')

  describe "when core:cancel is triggered", ->
    it "detaches from the DOM and focuses the the previously focused element", ->
      atom.workspaceView.attachToDom()
      atom.workspaceView.trigger("package-generator:generate-package")

      waitsForPromise ->
        activationPromise

      runs ->
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

      waitsForPromise ->
        activationPromise

      runs ->
        packageGeneratorView = atom.workspaceView.find(".package-generator").view()
        packageGeneratorView.miniEditor.setText(packagePath)
        apmExecute = spyOn(packageGeneratorView, 'runCommand')
        packageGeneratorView.trigger "core:confirm"

        expect(apmExecute).toHaveBeenCalled()
        expect(apmExecute.mostRecentCall.args[0]).toBe atom.packages.getApmPath()
        expect(apmExecute.mostRecentCall.args[1]).toEqual ['init', '--package', "#{path.join(path.dirname(packagePath), "camel-case-is-for-the-birds")}"]

    describe 'when creating a package', ->
      beforeEach ->
        atom.workspaceView.trigger("package-generator:generate-package")

        waitsForPromise ->
          activationPromise

      describe "when the package is created outside of the packages directory", ->
        it "calls `apm init` and `apm link`", ->
          packageGeneratorView = atom.workspaceView.find(".package-generator").view()
          expect(packageGeneratorView.hasParent()).toBeTruthy()
          packageGeneratorView.miniEditor.setText(packagePath)
          apmExecute = spyOn(packageGeneratorView, 'runCommand').andCallFake (command, args, exit) ->
            process.nextTick -> exit()
          packageGeneratorView.trigger "core:confirm"

          waitsFor ->
            atom.open.callCount is 1

          runs ->
            expect(apmExecute.argsForCall[0][0]).toBe atom.packages.getApmPath()
            expect(apmExecute.argsForCall[0][1]).toEqual ['init', '--package', "#{packagePath}"]
            expect(apmExecute.argsForCall[1][0]).toBe atom.packages.getApmPath()
            expect(apmExecute.argsForCall[1][1]).toEqual ['link', "#{packagePath}"]
            expect(atom.open.argsForCall[0][0].pathsToOpen[0]).toBe packagePath

      describe "when the package is created inside the packages directory", ->
        it "calls `apm init`", ->
          spyOn(atom.packages, 'getPackageDirPaths').andReturn [packageRoot]
          packageGeneratorView = atom.workspaceView.find(".package-generator").view()
          expect(packageGeneratorView.hasParent()).toBeTruthy()
          packageGeneratorView.miniEditor.setText(packagePath)
          apmExecute = spyOn(packageGeneratorView, 'runCommand').andCallFake (command, args, exit) ->
            process.nextTick -> exit()
          packageGeneratorView.trigger "core:confirm"

          waitsFor ->
            atom.open.callCount

          runs ->
            expect(apmExecute.argsForCall[0][0]).toBe atom.packages.getApmPath()
            expect(apmExecute.argsForCall[0][1]).toEqual ['init', '--package', "#{packagePath}"]
            expect(atom.open.argsForCall[0][0].pathsToOpen[0]).toBe packagePath

    describe 'when creating a theme', ->
      beforeEach ->
        atom.workspaceView.trigger("package-generator:generate-syntax-theme")

        waitsForPromise ->
          activationPromise

      describe "when the theme is created outside of the packages directory", ->
        it "calls `apm init` and `apm link`", ->
          packageGeneratorView = atom.workspaceView.find(".package-generator").view()
          expect(packageGeneratorView.hasParent()).toBeTruthy()
          packageGeneratorView.miniEditor.setText(packagePath)
          apmExecute = spyOn(packageGeneratorView, 'runCommand').andCallFake (command, args, exit) ->
            process.nextTick -> exit()
          packageGeneratorView.trigger "core:confirm"

          waitsFor ->
            atom.open.callCount is 1

          runs ->
            expect(apmExecute.argsForCall[0][0]).toBe atom.packages.getApmPath()
            expect(apmExecute.argsForCall[0][1]).toEqual ['init', '--theme', "#{packagePath}"]
            expect(apmExecute.argsForCall[1][0]).toBe atom.packages.getApmPath()
            expect(apmExecute.argsForCall[1][1]).toEqual ['link', "#{packagePath}"]
            expect(atom.open.argsForCall[0][0].pathsToOpen[0]).toBe packagePath

      describe "when the theme is created inside of the packages directory", ->
        it "calls `apm init`", ->
          spyOn(atom.packages, 'getPackageDirPaths').andReturn [packageRoot]
          packageGeneratorView = atom.workspaceView.find(".package-generator").view()
          expect(packageGeneratorView.hasParent()).toBeTruthy()
          packageGeneratorView.miniEditor.setText(packagePath)
          apmExecute = spyOn(packageGeneratorView, 'runCommand').andCallFake (command, args, exit) ->
            process.nextTick -> exit()
          packageGeneratorView.trigger "core:confirm"

          waitsFor ->
            atom.open.callCount is 1

          runs ->
            expect(apmExecute.argsForCall[0][0]).toBe atom.packages.getApmPath()
            expect(apmExecute.argsForCall[0][1]).toEqual ['init', '--theme', "#{packagePath}"]
            expect(atom.open.argsForCall[0][0].pathsToOpen[0]).toBe packagePath

    it "displays an error when the package path already exists", ->
      atom.workspaceView.attachToDom()
      fs.makeTreeSync(packagePath)
      atom.workspaceView.trigger("package-generator:generate-package")

      waitsForPromise ->
        activationPromise

      runs ->
        packageGeneratorView = atom.workspaceView.find(".package-generator").view()

        expect(packageGeneratorView.hasParent()).toBeTruthy()
        expect(packageGeneratorView.error).not.toBeVisible()
        packageGeneratorView.miniEditor.setText(packagePath)
        packageGeneratorView.trigger "core:confirm"
        expect(packageGeneratorView.hasParent()).toBeTruthy()
        expect(packageGeneratorView.error).toBeVisible()

    it "opens the package", ->
      atom.workspaceView.trigger("package-generator:generate-package")

      waitsForPromise ->
        activationPromise

      runs ->
        packageGeneratorView = atom.workspaceView.find(".package-generator").view()
        packageGeneratorView.miniEditor.setText(packagePath)
        apmExecute = spyOn(packageGeneratorView, 'runCommand').andCallFake (command, args, exit) ->
          process.nextTick -> exit()
        loadPackage = spyOn(atom.packages, 'loadPackage')
        packageGeneratorView.trigger "core:confirm"

      waitsFor ->
        atom.open.callCount is 1

      runs ->
        expect(atom.open).toHaveBeenCalledWith(pathsToOpen: [packagePath])
