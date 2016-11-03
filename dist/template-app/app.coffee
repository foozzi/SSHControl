app = require('app')
# Module to control application life.
os = require('os')
xss = require('xss')
fs = require('fs')
directoryExists = require('directory-exists')
# var shortid = require('shortid');

init = (path, cb) ->
  # check db path
  if !directoryExists.sync(path)
    fs.mkdir path
    return cb()
  cb()

require('require-rebuild')()
BrowserWindow = require('browser-window')
# Module to create native browser window.
ipcMain = require('electron').ipcMain
LinvoDB = require('linvodb3')
LinvoDB.defaults.store = db: require('leveldown')
init os.homedir() + '/.sshcontroll', ->
  # database path
  LinvoDB.dbPath = os.homedir() + '/.sshcontroll'
  #
  return
# owner model
Owner = new LinvoDB('owner', {})
# 
# records model
Records = new LinvoDB('records', {})
# 
mainWindow = null
# Quit when all windows are closed.
app.on 'window-all-closed', ->
  # On OS X it is common for applications and their menu bar
  # to stay active until the user quits explicitly with Cmd + Q
  if process.platform != 'darwin'
    app.quit()
  return
# This method will be called when Electron has finished
# initialization and is ready to create browser windows.
app.on 'ready', ->
  # Create the browser window.

  ValidateIPaddress = (ip, cb) ->
    if /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/.test(ip)
      return cb(true)
    cb false

  add_record = (datas, cb) ->
    if typeof datas.name_record == 'undefined'
      return cb(null,
        error: 1
        message: 'Name is required')
    else if typeof datas.ip_record == ' undefined'
      return cb(null,
        error: 1
        message: 'IP is required')
    else if typeof datas.psswd_record == 'undefined'
      return cb(null,
        error: 1
        message: 'Password is required')
    else if typeof datas.login_record == 'undefined'
      return cb(null,
        error: 1
        message: 'Login is required')
    name = xss(datas.name_record)
    login = xss(datas.login_record)
    ValidateIPaddress datas.ip_record, (response) ->
      if !response
        return cb(null,
          error: 1
          message: 'IP is not valid IPV4')
      return
    ip = xss(datas.ip_record)
    password = datas.psswd_record
    port = 22
    login = datas.login_record
    if typeof datas.port_record != 'undefined'
      if isNaN(datas.port_record)
        return cb(null,
          error: 1
          message: 'Port must be a number')
      port = datas.port_record
    data = 
      name: name
      login: login
      ip: ip
      password: password
      port: port
      createAt: parseInt((new Date).getTime() / 1000)
    Records.insert data, (err, newDoc) ->
      if !err
        return cb(null, newDoc)
      cb err, null
    return

  # @TODO add count and offset 

  get_record = (cb) ->
    # if(isNaN(count)){
    #   return cb(null, {error:1,message:'Count must be a number'});
    # }
    Records.find({}).sort('createAt': 1).exec (err, docs) ->
      if !err
        return cb(null, docs)
      cb err, null
    return

  mainWindow = new BrowserWindow(
    width: 900
    height: 750
    'min-width': 900
    'min-height': 750
    'accept-first-mouse': true
    'title-bar-style': 'hidden')
  ipcMain.on 'check_user', (event, args) ->
    Owner.find {}, (err, docs) ->
      if !err
        if docs.length < 1
          event.sender.send 'check_user',
            error: 0
            message: ''
            main_password: false
          return
        else
          event.sender.send 'check_user',
            error: 0
            message: ''
            main_password: true
          return
      return
    return
  ipcMain.on 'set_main_password', (event, args) ->
    if typeof args.psswd_1 == 'undefined'
      event.sender.send 'set_main_password',
        error: 1
        message: 'Password field is required'
      return
    if typeof args.psswd_2 == 'undefined'
      event.sender.send 'set_main_password',
        error: 1
        message: 'Password 2 field is required'
      return
    if args.psswd_1.trim() != args.psswd_2.trim()
      event.sender.send 'set_main_password',
        error: 1
        message: 'Password is different'
      return
    Owner.insert { password: args.psswd_1.trim() }, (err, newDoc) ->
      if !err
        event.sender.send 'set_main_password',
          error: 0
          message: ''
          response: newDoc._id
        return
      event.sender.send 'set_main_password',
        error: 1
        message: ''
        response: err
      return
    return
  ipcMain.on 'login_main', (event, args) ->
    Owner.find {}, (err, docs) ->
      if !err
        if docs.length < 1
          event.sender.send 'login_main',
            error: 1
            message: 'Owner is not found'
            main_password: false
          return
        else
          if docs[0].password != args.psswd
            event.sender.send 'login_main',
              error: 1
              message: 'Wrong password'
              main_password: false
            return
          event.sender.send 'login_main',
            error: 0
            message: ''
            main_password: true
          return
      return
    return
  ipcMain.on 'check_records', (event, args) ->
    get_record (err, result) ->
      if !err
        event.sender.send 'check_records',
          error: 0
          message: ''
          records_count: result.length
          records: result
      event.sender.send 'check_records',
        error: 1
        message: ''
        records_count: 0
        records: null
      return
    return
  ipcMain.on 'get_record', (event, args) ->
    Records.findOne {_id: args}, (err, docs) ->
      if !err
        event.sender.send 'get_record',
          error: 0
          message: ''
          record: docs
        return
      event.sender.send 'get_record',
        error: 1
        message: err
        record: null
      return
    return
  ipcMain.on 'add_records', (event, args) ->
    add_record args, (err, result) ->
      if err
        event.sender.send 'add_records',
          error: 1
          message: err.message
        return
      event.sender.send 'add_records',
        error: 0
        message: 'Data is inserted'
      return
    return
  # and load the index.html of the app.
  mainWindow.loadURL 'file://' + __dirname + '/index.html'
  # mainWindow.webContents.openDevTools();
  # Open the DevTools.
  # mainWindow.openDevTools()
  # Emitted when the window is closed.
  mainWindow.on 'closed', ->
    # Dereference the window object, usually you would store windows
    # in an array if your app supports multi windows, this is the time
    # when you should delete the corresponding element.
    mainWindow = null
    return
  return
