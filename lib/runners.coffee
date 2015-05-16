{isStoredInDotAtom} = require './validation'
{BufferedProcess} = require 'atom'

initPackage = (mode, saveLocation, callback) ->
  runCommand(atom.packages.getApmPath(), ['init', "--#{mode}", "#{saveLocation}"], callback)

linkPackage = (packagePath, callback) ->
  args = ['link']
  args.push('--dev') if atom.config.get('package-generator.createInDevMode')
  args.push packagePath.toString()

  runCommand(atom.packages.getApmPath(), args, callback)

createPackageFiles = (mode, saveLocation, callback) ->
  if isStoredInDotAtom(saveLocation)
    initPackage mode, saveLocation, callback
  else
    initPackage mode, saveLocation, => linkPackage(saveLocation, callback)

runCommand = (command, args, exit) ->
  new BufferedProcess({command, args, exit})


module.exports = {
  createPackageFiles
  initPackage
  linkPackage
  runCommand
}
