path = require 'path'
fs = require 'fs-plus'
{validPermission} = require './permission'

isStoredInDotAtom = (packagePath) ->
  packagesPath = path.join(atom.getConfigDirPath(), 'packages', path.sep)
  return true if packagePath.indexOf(packagesPath) is 0

  devPackagesPath = path.join(atom.getConfigDirPath(), 'dev', 'packages', path.sep)
  packagePath.indexOf(devPackagesPath) is 0

makeSureDirectoryExists = (saveLocation) ->
  dir = path.dirname saveLocation
  if not fs.existsSync dir
    create = confirm "#{dir} does not exist. Would you like to make a new one?", "Folder doesn't exist"
    if create
      fs.mkdirSync dir
      return true
    else
      return false

  return true

module.exports = {
  isStoredInDotAtom
  makeSureDirectoryExists
}
