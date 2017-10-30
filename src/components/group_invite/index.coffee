z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

FindFriends = require '../find_friends'
HeadsUp = require '../heads_up'

if window?
  require './index.styl'

HEADS_UP_TTL_MS = 2000

module.exports = class GroupInvite
  constructor: ({@model, @router, group}) ->
    @headsUpNotification = new RxBehaviorSubject null
    @$invitedHeadsUp = new HeadsUp {notification: @headsUpNotification}
    @$findFriends = new FindFriends {@model}

    @state = z.state {group}

  render: =>
    {group} = @state.getValue()

    z '.z-group-invite',
      z @$findFriends, {
        showCurrentFriends: true
        alwaysShowBack: true
        onBack: =>
          @router.back()
        onclick: (user) =>
          @headsUpNotification.next {
            title: @model.l.get 'groupInvite.headsUpNotificationTitle'
            details: @model.l.get 'groupInvite.headsUpNotificationDetails'
            ttlMs: HEADS_UP_TTL_MS
          }
          @model.group.inviteById group?.id, {
            userIds: [user.id]
          }
      }
      z @$invitedHeadsUp
