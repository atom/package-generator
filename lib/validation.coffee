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

whenNoDirectory = (finalPackageLocation, callback) ->
  if not makeSureDirectoryExists finalPackageLocation
    callback()
    return false
  true

alreadyExists = (finalPackageLocation, callback) ->
  if fs.existsSync(finalPackageLocation)
    callback()
    return false
  true

validPermission = (finalPackageLocation, callback) ->
  if not validPermission(finalPackageLocation)
    @showError "You do not have the right to save at #{finalPackageLocation}"
    return false
  true

module.exports = {
  whenNoDirectory
  alreadyExists
  validPermission
  isStoredInDotAtom
  makeSureDirectoryExists
}
