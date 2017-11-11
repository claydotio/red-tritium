z = require 'zorium'
isUuid = require 'isuuid'

Head = require '../../components/head'
GroupSettings = require '../../components/group_settings'
ButtonBack = require '../../components/button_back'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupSettingsPage
  hideDrawer: true
  isGroup: true

  constructor: ({@model, requests, @router, serverData}) ->
    group = requests.switchMap ({route}) =>
      if isUuid route.params.id
        @model.group.getById route.params.id
      else
        @model.group.getByKey route.params.id

    gameKey = requests.map ({route}) ->
      route.params.gameKey or config.DEFAULT_GAME_KEY

    @$head = new Head({
      @model
      requests
      serverData
      meta: {
        title: @model.l.get 'groupSettingsPage.title'
        description: @model.l.get 'groupSettingsPage.title'
      }
    })
    @$buttonBack = new ButtonBack {@model, @router}
    @$groupSettings = new GroupSettings {
      @model, @router, serverData, group, gameKey
    }

    @state = z.state
      windowSize: @model.window.getSize()

  renderHead: => @$head

  render: =>
    {windowSize} = @state.getValue()

    z '.p-group-settings', {
      style:
        height: "#{windowSize.height}px"
    },
      @$groupSettings
