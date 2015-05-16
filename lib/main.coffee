PackageGeneratorView = require './package-generator-view'


module.exports =
  config:
    createInDevMode:
      default: false
      type: 'boolean'

  activate: ->
    @view = new PackageGeneratorView()

  deactivate: ->
    @view?.destroy()
