fs = require 'fs'

module.exports.runSpecSuiteV2 = (specSuite, logFile) ->
  jasmineRequire = require("../vendor/jasmine-2.2.0")
  window.jasmine = jasmineRequire.core(jasmineRequire)
  jasmineInterface = jasmineRequire.interface(jasmine, jasmine.getEnv())
  jasmineRequire.html(jasmine)
  window[key] = value for key, value of jasmineInterface

  atom.initialize()
  atom.themes.requireStylesheet '../static/jasmine-2.2.0.css'

  require specSuite

  htmlReporter = new jasmine.HtmlReporter(
    env: jasmine.getEnv()
    onRaiseExceptionsClick: ->
    addToExistingQueryString: (key, value) ->
    getContainer: -> document.body
    createElement: -> document.createElement.apply(document, arguments)
    createTextNode: -> document.createTextNode.apply(document, arguments)
    timer: new jasmine.Timer()
  )
  htmlReporter.initialize()

  jasmineEnv = jasmine.getEnv()
  jasmineEnv.addReporter(htmlReporter)

  jasmineContent = document.createElement("div")
  jasmineContent.id = "jasmine-content"
  document.body.appendChild(jasmineContent)

  jasmineEnv.execute()

module.exports.runSpecSuite = (specSuite, logFile, logErrors=true) ->
  window[key] = value for key, value of require '../vendor/jasmine'

  {TerminalReporter} = require 'jasmine-tagged'
  require './spec-helper'

  disableFocusMethods() if process.env.JANKY_SHA1

  TimeReporter = require './time-reporter'
  timeReporter = new TimeReporter()

  logStream = fs.openSync(logFile, 'w') if logFile?
  log = (str) ->
    if logStream?
      fs.writeSync(logStream, str)
    else
      process.stderr.write(str)

  if atom.getLoadSettings().exitWhenDone
    reporter = new TerminalReporter
      print: (str) ->
        log(str)
      onComplete: (runner) ->
        fs.closeSync(logStream) if logStream?
        if process.env.JANKY_SHA1
          grim = require 'grim'
          grim.logDeprecations() if grim.getDeprecationsLength() > 0
        atom.exit(runner.results().failedCount > 0 ? 1 : 0)
  else
    AtomReporter = require './atom-reporter'
    reporter = new AtomReporter()

  require specSuite

  jasmineEnv = jasmine.getEnv()
  jasmineEnv.addReporter(reporter)
  jasmineEnv.addReporter(timeReporter)
  jasmineEnv.setIncludedTags([process.platform])

  jasmineContent = document.createElement("div")
  jasmineContent.id = "jasmine-content"
  document.body.appendChild(jasmineContent)

  jasmineEnv.execute()

disableFocusMethods = ->
  ['fdescribe', 'ffdescribe', 'fffdescribe', 'fit', 'ffit', 'fffit'].forEach (methodName) ->
    focusMethod = window[methodName]
    window[methodName] = (description) ->
      error = new Error('Focused spec is running on CI')
      focusMethod description, -> throw error
