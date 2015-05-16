fs = require 'fs-plus'
path = require 'path'

userIsOwner = (stats) ->
  owner = (process.getuid() is stats.uid)
  owner && (stats.mode & 0o00200)

usersGroupCanWrite = (stats) ->
  inGroup = (process.getgid() is stats.gid)
  inGroup && (stats.mode & 0o00020)

anyoneCanWrite = (stats) ->
  stats.mode & 0o00002

validPermission= (saveLocation) ->
  stats = fs.statSync path.dirname(saveLocation)
  if userIsOwner(stats) or
     usersGroupCanWrite(stats) or
     anyoneCanWrite(stats)
    return true
  else
    false

module.exports = {
  userIsOwner
  usersGroupCanWrite
  anyoneCanWrite
  validPermission
}
