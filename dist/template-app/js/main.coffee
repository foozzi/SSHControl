is_login = false
handlebars = require('handlebars')

check_records = (ipcRenderer) ->
  ipcRenderer.send 'check_records', ''
  ipcRenderer.once 'check_records', (event, arg) ->
    if arg.error != 0
      new Notification('SSHControl', [ { body: arg.message } ][0])
      return false
    $('.welcome-title').hide()
    if arg.records_count != 0
      $('.sidebar').show()
      source = $('#main-box-template').html()
      template = handlebars.compile(source)
      records = arg.records
      $('#records').html ''
      $(records).each ->
        $('#records').append template(
          name: @name
          ip: @ip
          id: @_id)
        return
      $('.view*').click ->
        $('.view').removeClass 'active'
        $(this).addClass 'active'
        $('.main-add-records-box').hide()
        id = $(this).attr('id')
        ipcRenderer.send 'get_record', id
        ipcRenderer.once 'get_record', (event, arg) ->
          record = null;
          source = $('#view-box-template').html()
          template = handlebars.compile(source)
          record = arg.record
          $('#view-record').html ''
          $('.main-view-record-box').show()
          $('#view-record').append template(
            name: record.name
            ip: record.ip
            id: record._id
            port: record.port
            password: record.password
            login: record.login)
          $('input#ssh-data').on 'click', ->
            $(this).select()
            return
          $('input#ssh-password').on 'click', ->
            $(this).select()
            return
          return
        false
    return
  return

$(document).ready ->
  path = require('path')
  ipcRenderer = require('electron').ipcRenderer
  remote = require('electron').remote
  Menu = remote.Menu
  InputMenu = Menu.buildFromTemplate([
    {
      label: 'Undo'
      role: 'undo'
    }
    {
      label: 'Redo'
      role: 'redo'
    }
    { type: 'separator' }
    {
      label: 'Cut'
      role: 'cut'
    }
    {
      label: 'Copy'
      role: 'copy'
    }
    {
      label: 'Paste'
      role: 'paste'
    }
    { type: 'separator' }
    {
      label: 'Select all'
      role: 'selectall'
    }
  ])
  document.body.addEventListener 'contextmenu', (e) ->
    e.preventDefault()
    e.stopPropagation()
    node = e.target
    while node
      if node.nodeName.match(/^(input|textarea)$/i) or node.isContentEditable
        InputMenu.popup remote.getCurrentWindow()
        break
      node = node.parentNode
    return
  ipcRenderer.send 'check_user', ''
  ipcRenderer.once 'check_user', (event, arg) ->
    if arg.main_password == false
      $('.main-password-box-register').show()
      false
    else
      $('.main-password-box-login').show()
      false
  $('form#form-add-records-box').submit ->
    serialize = require('form-serialize')
    form = serialize(this, hash: true)
    ipcRenderer.send 'add_records', form
    ipcRenderer.once 'add_records', (event, arg) ->
      if arg.error != 0
        new Notification('SSHControl', [ { body: arg.message } ][0])
        return false
      $('form#form-add-records-box')[0].reset()
      # new Notification('SSHControl', [{body:arg.message}][0]);
      check_records ipcRenderer
      # get_record(ipcRenderer);
      false
    false
  $('form#form-set-main-password-register').submit ->
    serialize = require('form-serialize')
    form = serialize(this, hash: true)
    ipcRenderer.send 'set_main_password', form
    ipcRenderer.once 'set_main_password', (event, arg) ->
      is_login = true
      $('.image-title').hide()
      $('.main-password-box-register').hide()
      $('.main-add-records-box').show()
      return
    false
  $('form#form-set-main-password-login').submit ->
    serialize = require('form-serialize')
    form = serialize(this, hash: true)
    ipcRenderer.send 'login_main', form
    ipcRenderer.once 'login_main', (event, arg) ->
      if arg.error != 0
        new Notification('SSHControl', [ { body: arg.message } ][0])
        return false
      $('.image-title').hide()
      $('.main-password-box-login').hide()
      $('.main-add-records-box').show()
      check_records ipcRenderer
      is_login = true
      # get_record(ipcRenderer);
      return
    false
  $('#to-home').on 'click', ->
    if !is_login
      new Notification('SSHControl', [ { body: 'Please login with main password' } ][0])
      return false
    $('#view-record').html ''
    $('.main-add-records-box').show()
    $('.view').removeClass 'active'
    false
  return