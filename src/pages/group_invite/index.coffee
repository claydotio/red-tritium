z = require 'zorium'
isUuid = require 'isuuid'

Head = require '../../components/head'
GroupInvite = require '../../components/group_invite'

if window?
  require './index.styl'

module.exports = class GroupInvitePage
  hideDrawer: true
  isGroup: true

  constructor: ({model, requests, @router, serverData, group}) ->
    @$head = new Head({
      model
      requests
      serverData
      meta: {
        title: model.l.get 'groupInvitePage.title'
        description: model.l.get 'groupInvitePage.title'
      }
    })
    @$groupInvite = new GroupInvite {model, @router, serverData, group}

    @state = z.state
      windowSize: model.window.getSize()

  renderHead: => @$head

  render: =>
    {windowSize} = @state.getValue()

    z '.p-group-invite', {
      style:
        height: "#{windowSize.height}px"
    },
      @$groupInvite
