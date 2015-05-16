_ = require 'underscore-plus'

sanitizeNameInput = (textField) ->
  _.dasherize(textField.getText()).trim()

module.exports = {
  sanitizeNameInput
}
