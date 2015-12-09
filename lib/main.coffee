PackageGeneratorView = require './package-generator-view'

module.exports =
  activate: ->
    @view = new PackageGeneratorView()

  deactivate: ->
    @view?.destroy()
