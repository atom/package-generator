PackageGeneratorView = require './package-generator-view'

module.exports =
  config:
    createInDevMode:
      default: true
      type: 'boolean'

  activate: ->
    @view = new PackageGeneratorView()

  deactivate: ->
    @view?.remove()
