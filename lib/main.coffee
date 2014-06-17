PackageGeneratorView = require './package-generator-view'

module.exports =
  configDefaults:
    createInDevMode: false

  activate: ->
    @view = new PackageGeneratorView()

  deactivate: ->
    @view?.remove()
