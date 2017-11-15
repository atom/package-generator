path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
_ = require 'underscore-plus'
PackageGeneratorView = require '../lib/package-generator-view'

describe 'Package Generator', ->
  [activationPromise] = []

  getWorkspaceView = -> atom.views.getView(atom.workspace)
  getEditorView = -> atom.views.getView(atom.workspace.getActiveTextEditor())

  beforeEach ->
    waitsForPromise ->
      atom.workspace.open('sample.js')

    runs ->
      activationPromise = atom.packages.activatePackage("package-generator")

  describe "when package-generator:generate-package is triggered", ->
    it "displays a miniEditor with the correct text and selection", ->
      atom.commands.dispatch(getWorkspaceView(), "package-generator:generate-package")

      waitsForPromise ->
        activationPromise

      runs ->
        packageGeneratorView = getWorkspaceView().querySelector(".package-generator")
        editor = packageGeneratorView.querySelector('atom-text-editor').getModel()
        expect(editor.getSelectedText()).toEqual 'my-package'
        base = atom.config.get 'core.projectHome'
        expect(editor.getText()).toEqual path.join(base, 'my-package')

    describe "when ATOM_REPOS_HOME is set", ->
      beforeEach ->
        process.env.ATOM_REPOS_HOME = "/atom/repos/home"

      afterEach ->
        delete process.env.ATOM_REPOS_HOME

      it "overrides the default path", ->
        atom.commands.dispatch(getWorkspaceView(), "package-generator:generate-package")

        waitsForPromise ->
          activationPromise

        runs ->
          packageGeneratorView = getWorkspaceView().querySelector(".package-generator")
          editor = packageGeneratorView.querySelector('atom-text-editor').getModel()
          expect(editor.getSelectedText()).toEqual 'my-package'
          base = "/atom/repos/home"
          expect(editor.getText()).toEqual path.join(base, 'my-package')

  describe "when package-generator:generate-syntax-theme is triggered", ->
    it "displays a miniEditor with correct text and selection", ->
      atom.commands.dispatch(getWorkspaceView(), "package-generator:generate-syntax-theme")

      waitsForPromise ->
        activationPromise

      runs ->
        packageGeneratorView = getWorkspaceView().querySelector(".package-generator")
        editor = packageGeneratorView.querySelector('atom-text-editor').getModel()
        expect(editor.getSelectedText()).toEqual 'my-theme'
        base = atom.config.get 'core.projectHome'
        expect(editor.getText()).toEqual path.join(base, 'my-theme-syntax')

  describe "when core:cancel is triggered", ->
    it "detaches from the DOM and focuses the the previously focused element", ->
      jasmine.attachToDOM(getWorkspaceView())
      atom.commands.dispatch(getWorkspaceView(), "package-generator:generate-package")

      waitsForPromise ->
        activationPromise

      runs ->
        packageGeneratorView = getWorkspaceView().querySelector(".package-generator")
        expect(document.activeElement.closest('atom-text-editor')).toBe(packageGeneratorView.querySelector('atom-text-editor'))

        atom.commands.dispatch(packageGeneratorView, "core:cancel")
        expect(atom.workspace.getModalPanels()[0].isVisible()).toBe(false)
        expect(document.activeElement.closest('atom-text-editor')).toBe(getEditorView())

  describe "when a package is generated", ->
    [packageName, packagePath, packageRoot] = []

    packageInitCommandFor = (path, syntax) ->
      syntax ||= atom.config.get('package-generator.packageSyntax')
      ['init', '--package', path, '--syntax', syntax]

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
      atom.commands.dispatch(getWorkspaceView(), "package-generator:generate-package")

      waitsForPromise ->
        activationPromise

      runs ->
        packageGeneratorView = getWorkspaceView().querySelector('.package-generator')
        editor = packageGeneratorView.querySelector('atom-text-editor').getModel()
        editor.setText(packagePath)
        apmExecute = spyOn(PackageGeneratorView::, 'runCommand')
        atom.commands.dispatch(packageGeneratorView, "core:confirm")

        expect(apmExecute).toHaveBeenCalled()
        expect(apmExecute.mostRecentCall.args[0]).toBe atom.packages.getApmPath()
        expect(apmExecute.mostRecentCall.args[1]).toEqual packageInitCommandFor "#{path.join(path.dirname(packagePath), "camel-case-is-for-the-birds")}"

    it "normalizes the package's path", ->
      packagePath = path.join("~", "the-package")
      atom.commands.dispatch(getWorkspaceView(), "package-generator:generate-package")

      waitsForPromise ->
        activationPromise

      runs ->
        packageGeneratorView = getWorkspaceView().querySelector('.package-generator')
        editor = packageGeneratorView.querySelector('atom-text-editor').getModel()
        editor.setText(packagePath)
        apmExecute = spyOn(PackageGeneratorView::, 'runCommand')
        atom.commands.dispatch(packageGeneratorView, "core:confirm")

        expect(apmExecute).toHaveBeenCalled()
        expect(apmExecute.mostRecentCall.args[0]).toBe atom.packages.getApmPath()
        expect(apmExecute.mostRecentCall.args[1]).toEqual packageInitCommandFor "#{fs.normalize(packagePath)}"

    describe 'when creating a package', ->
      [apmExecute] = []

      generatePackage = (insidePackagesDirectory, callback) ->
        packageGeneratorView = getWorkspaceView().querySelector('.package-generator')
        editor = packageGeneratorView.querySelector('atom-text-editor').getModel()
        spyOn(PackageGeneratorView::, 'isStoredInDotAtom').andReturn insidePackagesDirectory
        expect(packageGeneratorView.parentElement).toBeTruthy()
        editor.setText(packagePath)
        apmExecute = spyOn(PackageGeneratorView::, 'runCommand').andCallFake (command, args, exit) ->
          process.nextTick -> exit()
        atom.commands.dispatch(packageGeneratorView, "core:confirm")
        waitsFor ->
          atom.open.callCount is 1
        runs callback

      generateOutside = _.partial generatePackage, false
      generateInside = _.partial generatePackage, true

      beforeEach ->
        atom.commands.dispatch(getWorkspaceView(), "package-generator:generate-package")

        waitsForPromise ->
          activationPromise

      describe "when the package is created outside of the packages directory", ->

        it "calls `apm init` and `apm link`", ->
          atom.config.set 'package-generator.createInDevMode', false

          generateOutside ->
            expect(apmExecute.argsForCall[0][0]).toBe atom.packages.getApmPath()
            expect(apmExecute.argsForCall[0][1]).toEqual packageInitCommandFor "#{packagePath}"
            expect(apmExecute.argsForCall[1][0]).toBe atom.packages.getApmPath()
            expect(apmExecute.argsForCall[1][1]).toEqual ['link', "#{packagePath}"]
            expect(atom.open.argsForCall[0][0].pathsToOpen[0]).toBe packagePath

        it "calls `apm init` and `apm link --dev`", ->
          atom.config.set 'package-generator.createInDevMode', true

          generateOutside ->
            expect(apmExecute.argsForCall[0][0]).toBe atom.packages.getApmPath()
            expect(apmExecute.argsForCall[0][1]).toEqual packageInitCommandFor "#{packagePath}"
            expect(apmExecute.argsForCall[1][0]).toBe atom.packages.getApmPath()
            expect(apmExecute.argsForCall[1][1]).toEqual ['link', '--dev', "#{packagePath}"]
            expect(atom.open.argsForCall[0][0].pathsToOpen[0]).toBe packagePath

      describe "when the package is created inside the packages directory", ->
        it "calls `apm init`", ->
          generateInside ->
            expect(apmExecute.argsForCall[0][0]).toBe atom.packages.getApmPath()
            expect(apmExecute.argsForCall[0][1]).toEqual packageInitCommandFor "#{packagePath}"
            expect(atom.open.argsForCall[0][0].pathsToOpen[0]).toBe packagePath
            expect(apmExecute.argsForCall[1]).toBeUndefined()

      describe "when the package is a coffeescript package", ->
        it "calls `apm init` with the correct syntax option", ->
          atom.config.set 'package-generator.packageSyntax', 'coffeescript'
          generateInside ->
            expect(apmExecute.argsForCall[0][0]).toBe atom.packages.getApmPath()
            expect(apmExecute.argsForCall[0][1]).toEqual packageInitCommandFor "#{packagePath}", 'coffeescript'

      describe "when the package is a javascript package", ->
        it "calls `apm init` with the correct syntax option", ->
          atom.config.set 'package-generator.packageSyntax', 'javascript'
          generateInside ->
            expect(apmExecute.argsForCall[0][0]).toBe atom.packages.getApmPath()
            expect(apmExecute.argsForCall[0][1]).toEqual packageInitCommandFor "#{packagePath}", 'javascript'

    describe 'when creating a theme', ->
      beforeEach ->
        atom.commands.dispatch(getWorkspaceView(), "package-generator:generate-syntax-theme")

        waitsForPromise ->
          activationPromise

      describe "when the theme is created outside of the packages directory", ->
        it "calls `apm init` and `apm link`", ->
          packageGeneratorView = getWorkspaceView().querySelector('.package-generator')
          expect(packageGeneratorView.parentElement).toBeTruthy()
          editor = packageGeneratorView.querySelector('atom-text-editor').getModel()
          editor.setText(packagePath)
          apmExecute = spyOn(PackageGeneratorView::, 'runCommand').andCallFake (command, args, exit) ->
            process.nextTick -> exit()
          atom.commands.dispatch(packageGeneratorView, "core:confirm")

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
          packageGeneratorView = getWorkspaceView().querySelector('.package-generator')
          editor = packageGeneratorView.querySelector('atom-text-editor').getModel()
          spyOn(PackageGeneratorView::, 'isStoredInDotAtom').andReturn true
          expect(packageGeneratorView.parentElement).toBeTruthy()
          editor.setText(packagePath)
          apmExecute = spyOn(PackageGeneratorView::, 'runCommand').andCallFake (command, args, exit) ->
            process.nextTick -> exit()
          atom.commands.dispatch(packageGeneratorView, "core:confirm")

          waitsFor ->
            atom.open.callCount is 1

          runs ->
            expect(apmExecute.argsForCall[0][0]).toBe atom.packages.getApmPath()
            expect(apmExecute.argsForCall[0][1]).toEqual ['init', '--theme', "#{packagePath}"]
            expect(atom.open.argsForCall[0][0].pathsToOpen[0]).toBe packagePath
            expect(apmExecute.argsForCall[1]).toBeUndefined()

    it "displays an error when the package path already exists", ->
      jasmine.attachToDOM(getWorkspaceView())
      fs.makeTreeSync(packagePath)
      atom.commands.dispatch(getWorkspaceView(), "package-generator:generate-package")

      waitsForPromise ->
        activationPromise

      runs ->
        packageGeneratorView = getWorkspaceView().querySelector('.package-generator')
        editor = packageGeneratorView.querySelector('atom-text-editor').getModel()
        expect(packageGeneratorView.parentElement).toBeTruthy()
        expect(packageGeneratorView.querySelector('.error').offsetHeight).toBe(0)
        editor.setText(packagePath)
        atom.commands.dispatch(packageGeneratorView, "core:confirm")
        expect(packageGeneratorView.parentElement).toBeTruthy()
        expect(packageGeneratorView.querySelector('.error').offsetHeight).not.toBe(0)

    it "opens the package", ->
      atom.commands.dispatch(getWorkspaceView(), "package-generator:generate-package")

      waitsForPromise ->
        activationPromise

      runs ->
        packageGeneratorView = getWorkspaceView().querySelector('.package-generator')
        editor = packageGeneratorView.querySelector('atom-text-editor').getModel()
        editor.setText(packagePath)
        spyOn(PackageGeneratorView::, 'runCommand').andCallFake (command, args, exit) ->
          process.nextTick -> exit()
        spyOn(atom.packages, 'loadPackage')
        atom.commands.dispatch(packageGeneratorView, "core:confirm")

      waitsFor ->
        atom.open.callCount is 1

      runs ->
        expect(atom.open).toHaveBeenCalledWith(pathsToOpen: [packagePath])
