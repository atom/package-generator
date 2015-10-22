PackageGeneratorView = require './package-generator-view'

module.exports =
  config:
    createInDevMode:
      default: false
      type: 'boolean'
      description: 'When disabled, generated packages are linked into Atom in both normal mode and dev mode. When enabled, generated packages are linked into Atom only in dev mode.'

  activate: ->
    @view = new PackageGeneratorView()

  deactivate: ->
    @view?.destroy()
