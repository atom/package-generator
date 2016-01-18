PackageGeneratorView = require './package-generator-view'

module.exports =
  config:
    createInDevMode:
      default: false
      type: 'boolean'
      description: 'When disabled, generated packages are linked into Atom in both normal mode and dev mode. When enabled, generated packages are linked into Atom only in dev mode.'
    packageParams:
      title: 'Package parameters'
      default: ''
      type: 'string'
      description: 'Parameters related to apm init command for packages (```--syntax <javascript-or-coffeescript>```, ```-c <Path or URL to Textmate bundle>``` or ```--template <Path to template>```)'
    themeParams:
      title: 'Theme parameters'
      default: ''
      type: 'string'
      description: 'Parameters related to apm init command for themes (```-c <Path or URL to Textmate bundle>``` or ```--template <Path to template>```)'

  activate: ->
    @view = new PackageGeneratorView()

  deactivate: ->
    @view?.destroy()
