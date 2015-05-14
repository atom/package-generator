path = require 'path'
fs = require 'fs-plus'

isStoredInDotAtom = (packagePath) ->
  packagesPath = path.join(atom.getConfigDirPath(), 'packages', path.sep)
  return true if packagePath.indexOf(packagesPath) is 0

  devPackagesPath = path.join(atom.getConfigDirPath(), 'dev', 'packages', path.sep)
  packagePath.indexOf(devPackagesPath) is 0

module.exports = {
  isStoredInDotAtom
}
