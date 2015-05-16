path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
{$} = require 'atom-space-pen-views'

describe 'Package Generator', ->
  [activationPromise] = []

  getWorkspaceView = -> atom.views.getView(atom.workspace)
  getEditorView = -> atom.views.getView(atom.workspace.getActiveTextEditor())

  beforeEach ->
    spyOn(window, 'confirm').andReturn true
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
        packageGeneratorView = $(getWorkspaceView()).find(".package-generator").view()
        packageName = packageGeneratorView.nameEditor.getModel().getText()
        expect(packageName).toEqual 'my-awesome-package'

        fullPath = packageGeneratorView.buildPackagePath()
        base = atom.config.get 'core.projectHome'
        console.log fullPath
        expect(fullPath).toEqual path.join(base, 'my-awesome-package')

  describe "when package-generator:generate-syntax-theme is triggered", ->
    it "displays a pathEditor and nameEditor with correct text inside", ->
      atom.commands.dispatch(getWorkspaceView(), "package-generator:generate-syntax-theme")

      waitsForPromise ->
        activationPromise

      runs ->
        packageGeneratorView = $(getWorkspaceView()).find(".package-generator").view()
        themeName = packageGeneratorView.nameEditor.getModel().getText()
        expect(themeName).toEqual 'my-awesome-syntax'

        fullPath = packageGeneratorView.buildPackagePath()
        base = atom.config.get 'core.projectHome'
        expect(fullPath).toEqual path.join(base, 'my-awesome-syntax')

  describe "when core:cancel is triggered", ->
    it "detaches from the DOM and focuses the the previously focused element", ->
      jasmine.attachToDOM(getWorkspaceView())
      atom.commands.dispatch(getWorkspaceView(), "package-generator:generate-package")

      waitsForPromise ->
        activationPromise

      runs ->
        packageGeneratorView = $(getWorkspaceView()).find(".package-generator").view()
        expect(packageGeneratorView.nameEditor.element).toBe document.activeElement

        atom.commands.dispatch(packageGeneratorView.element, "core:cancel")
        expect(packageGeneratorView.panel.isVisible()).toBeFalsy()
        expect(getEditorView()).toBe document.activeElement

  # describe "when a package is generated", ->
  #   [packageName, packagePath, packageRoot] = []
  #
  #   beforeEach ->
  #     spyOn(atom, "open")
  #
  #     packageRoot = temp.mkdirSync('atom')
  #     packageName = "sweet-package-dude"
  #     packagePath = path.join(packageRoot, packageName)
  #
  #     fs.removeSync(packageRoot)
  #
  #   afterEach ->
  #     fs.removeSync(packageRoot)
  #
  #   it "forces the package's name to be lowercase with dashes", ->
  #     packageName = "CamelCaseIsForTheBirds"
  #     atom.commands.dispatch(getWorkspaceView(), "package-generator:generate-package")
  #
  #     waitsForPromise ->
  #       activationPromise
  #
  #     runs ->
  #       packageGeneratorView = $(getWorkspaceView()).find(".package-generator").view()
  #
  #       packageGeneratorView.nameEditor.setText(packageName)
  #       packageGeneratorView.pathEditor.setText(packageRoot)
  #
  #       expect(packageGeneratorView.buildPackagePath()).toEqual path.join(packageRoot, "camel-case-is-for-the-birds")
  # 
    # describe 'when creating a package', ->
    #   beforeEach ->
    #     atom.commands.dispatch(getWorkspaceView(), "package-generator:generate-package")
    #
    #     waitsForPromise ->
    #       activationPromise
    #
    #   describe "when the package is created outside of the packages directory", ->
    #     [apmExecute] = []
    #
    #     generateOutside = (callback) ->
    #       packageGeneratorView = $(getWorkspaceView()).find(".package-generator").view()
    #       expect(packageGeneratorView.hasParent()).toBeTruthy()
    #
    #       packageGeneratorView.nameEditor.setText(packageName)
    #       packageGeneratorView.pathEditor.setText(packageRoot)
    #
    #       apmExecute = spyOn(packageGeneratorView, 'runCommand').andCallFake (command, args, exit) ->
    #         process.nextTick -> exit()
    #       atom.commands.dispatch(packageGeneratorView.element, "core:confirm")
    #       waitsFor ->
    #         atom.open.callCount is 1
    #
    #       runs callback
    #
    #     it "calls `apm init` and `apm link`", ->
    #       atom.config.set 'package-generator.createInDevMode', false
    #
    #       generateOutside ->
    #         expect(apmExecute.argsForCall[0][0]).toBe atom.packages.getApmPath()
    #         expect(apmExecute.argsForCall[0][1]).toEqual ['init', '--package', "#{packagePath}"]
    #         expect(apmExecute.argsForCall[1][0]).toBe atom.packages.getApmPath()
    #         expect(apmExecute.argsForCall[1][1]).toEqual ['link', "#{packagePath}"]
    #         expect(atom.open.argsForCall[0][0].pathsToOpen[0]).toBe packagePath
    #
    #     it "calls `apm init` and `apm link --dev`", ->
    #       atom.config.set 'package-generator.createInDevMode', true
    #
    #       generateOutside ->
    #         expect(apmExecute.argsForCall[0][0]).toBe atom.packages.getApmPath()
    #         expect(apmExecute.argsForCall[0][1]).toEqual ['init', '--package', "#{packagePath}"]
    #         expect(apmExecute.argsForCall[1][0]).toBe atom.packages.getApmPath()
    #         expect(apmExecute.argsForCall[1][1]).toEqual ['link', '--dev', "#{packagePath}"]
    #         expect(atom.open.argsForCall[0][0].pathsToOpen[0]).toBe packagePath
    #
    #   describe "when the package is created inside the packages directory", ->
    #     it "calls `apm init`", ->
    #       packageGeneratorView = $(getWorkspaceView()).find(".package-generator").view()
    #       expect(packageGeneratorView.hasParent()).toBeTruthy()
    #
    #       packageGeneratorView.nameEditor.setText(packageName)
    #       packageGeneratorView.pathEditor.setText(packageRoot)
    #
    #       apmExecute = spyOn(packageGeneratorView, 'runCommand').andCallFake (command, args, exit) ->
    #         process.nextTick -> exit()
    #       atom.commands.dispatch(packageGeneratorView.element, "core:confirm")
    #
    #       waitsFor ->
    #         atom.open.callCount
    #
    #       runs ->
    #         expect(apmExecute.argsForCall[0][0]).toBe atom.packages.getApmPath()
    #         expect(apmExecute.argsForCall[0][1]).toEqual ['init', '--package', "#{packagePath}"]
    #         expect(atom.open.argsForCall[0][0].pathsToOpen[0]).toBe packagePath
    #         # unsure why the second parameter should be undefined
    #         # expect(apmExecute.argsForCall[1]).toBeUndefined()
    #
    # describe 'when creating a theme', ->
    #   beforeEach ->
    #     atom.commands.dispatch(getWorkspaceView(), "package-generator:generate-syntax-theme")
    #
    #     waitsForPromise ->
    #       activationPromise
    #
    #   describe "when the theme is created outside of the packages directory", ->
    #     it "calls `apm init` and `apm link`", ->
    #       packageGeneratorView = $(getWorkspaceView()).find(".package-generator").view()
    #       expect(packageGeneratorView.hasParent()).toBeTruthy()
    #
    #       packageGeneratorView.nameEditor.setText(packageName)
    #       packageGeneratorView.pathEditor.setText(packageRoot)
    #
    #       apmExecute = spyOn(packageGeneratorView, 'runCommand').andCallFake (command, args, exit) ->
    #         process.nextTick -> exit()
    #       atom.commands.dispatch(packageGeneratorView.element, "core:confirm")
    #
    #       waitsFor ->
    #         atom.open.callCount is 1
    #
    #       runs ->
    #         expect(apmExecute.argsForCall[0][0]).toBe atom.packages.getApmPath()
    #         expect(apmExecute.argsForCall[0][1]).toEqual ['init', '--theme', "#{packagePath}"]
    #         expect(apmExecute.argsForCall[1][0]).toBe atom.packages.getApmPath()
    #         expect(apmExecute.argsForCall[1][1]).toEqual ['link', "#{packagePath}"]
    #         expect(atom.open.argsForCall[0][0].pathsToOpen[0]).toBe packagePath
    #
    #   describe "when the theme is created inside of the packages directory", ->
    #     it "calls `apm init`", ->
    #       packageGeneratorView = $(getWorkspaceView()).find(".package-generator").view()
    #       expect(packageGeneratorView.hasParent()).toBeTruthy()
    #
    #       packageGeneratorView.nameEditor.setText(packageName)
    #       packageGeneratorView.pathEditor.setText(packageRoot)
    #
    #       apmExecute = spyOn(packageGeneratorView, 'runCommand').andCallFake (command, args, exit) ->
    #         process.nextTick -> exit()
    #       atom.commands.dispatch(packageGeneratorView.element, "core:confirm")
    #
    #       waitsFor ->
    #         atom.open.callCount is 1
    #
    #       runs ->
    #         expect(apmExecute.argsForCall[0][0]).toBe atom.packages.getApmPath()
    #         expect(apmExecute.argsForCall[0][1]).toEqual ['init', '--theme', "#{packagePath}"]
    #         expect(atom.open.argsForCall[0][0].pathsToOpen[0]).toBe packagePath
    #         # unsure why the second parameter should be undefined
    #         # expect(apmExecute.argsForCall[1]).toBeUndefined()
    #
    # it "displays an error when the package path already exists", ->
    #   jasmine.attachToDOM(getWorkspaceView())
    #   fs.makeTreeSync packagePath
    #   atom.commands.dispatch(getWorkspaceView(), "package-generator:generate-package")
    #
    #   waitsForPromise ->
    #     activationPromise
    #
    #   runs ->
    #     packageGeneratorView = $(getWorkspaceView()).find(".package-generator").view()
    #     expect(packageGeneratorView.hasParent()).toBeTruthy()
    #     expect(packageGeneratorView.error).not.toBeVisible()
    #
    #     packageGeneratorView.nameEditor.setText(packageName)
    #     packageGeneratorView.pathEditor.setText(packageRoot)
    #
    #     atom.commands.dispatch(packageGeneratorView.element, "core:confirm")
    #     expect(packageGeneratorView.hasParent()).toBeTruthy()
    #     expect(packageGeneratorView.error).toBeVisible()
    #
    # it "opens the package", ->
    #   atom.commands.dispatch(getWorkspaceView(), "package-generator:generate-package")
    #
    #   waitsForPromise ->
    #     activationPromise
    #
    #   runs ->
    #     packageGeneratorView = $(getWorkspaceView()).find(".package-generator").view()
    #
    #     packageGeneratorView.nameEditor.setText(packageName)
    #     packageGeneratorView.pathEditor.setText(packageRoot)
    #
    #     apmExecute = spyOn(packageGeneratorView, 'runCommand').andCallFake (command, args, exit) ->
    #       process.nextTick -> exit()
    #     loadPackage = spyOn(atom.packages, 'loadPackage')
    #     atom.commands.dispatch(packageGeneratorView.element, "core:confirm")
    #
    #   waitsFor ->
    #     atom.open.callCount is 1
    #
    #   runs ->
    #     expect(atom.open).toHaveBeenCalledWith(pathsToOpen: [packagePath])
