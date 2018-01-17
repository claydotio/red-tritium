z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'

Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

GROUPS_IN_DRAWER = 2

module.exports = class BottomBar
  constructor: ({@model, @router, requests, group}) ->
    @state = z.state
      requests: requests
      group: group

  afterMount: (@$$el) => null

  hide: =>
    @$$el?.classList.add 'is-hidden'

  show: =>
    @$$el?.classList.remove 'is-hidden'

  render: ({isAbsolute} = {}) =>
    {requests, group} = @state.getValue()
    currentPath = requests?.req.path

    groupId = group?.key or config.CLASH_ROYALE_ID
    isLoaded = Boolean group

    # per-group menu:
    # profile, tools, home, forum, chat
    @menuItems = _filter [
      {
        $icon: new Icon()
        icon: 'profile'
        route: @router.get 'groupProfile', {groupId}
        text: @model.l.get 'general.profile'
      }
      {
        $icon: new Icon()
        icon: 'chat'
        # route: @router.get 'groupChat', {groupId: 'playhard'}
        route: @router.get 'groupChat', {groupId}
        text: @model.l.get 'general.chat'
      }
      {
        $icon: new Icon()
        icon: 'home'
        route: @router.get 'groupHome', {
          groupId
        }
        text: @model.l.get 'general.home'
        isDefault: true
      }
      if group?.key is 'playhard'
        {
          $icon: new Icon()
          icon: 'shop'
          # route: @router.get 'groupForum', {groupId: 'playhard'}
          route: @router.get 'groupShop', {groupId}
          text: @model.l.get 'general.shop'
        }
      else if group?.type is 'public'
        {
          $icon: new Icon()
          icon: 'rss'
          # route: @router.get 'groupForum', {groupId: 'playhard'}
          route: @router.get 'groupForum', {groupId}
          text: @model.l.get 'general.forum'
        }
      {
        $icon: new Icon()
        icon: 'ellipsis'
        route: @router.get 'groupTools', {groupId}
        text: @model.l.get 'general.tools'
      }
    ]

    z '.z-bottom-bar', {
      key: 'bottom-bar'
      className: z.classKebab {isLoaded, isAbsolute}
    },
      _map @menuItems, ({$icon, icon, route, text, $ripple, isDefault}, i) =>
        if isDefault
          isSelected =  currentPath in [
            @router.get 'siteHome'
            @router.get 'groupHome', {groupId}
            '/'
          ]
        else
          isSelected = currentPath and currentPath.indexOf(route) isnt -1

        z 'a.menu-item', {
          attributes:
            tabindex: i
          className: z.classKebab {isSelected}
          href: route
          onclick: (e) =>
            e?.preventDefault()
            @router.goPath route
          # ontouchstart: (e) =>
          #   e?.stopPropagation()
          #   @router.goPath route
          # onclick: (e) =>
          #   e?.stopPropagation()
          #   @router.goPath route
        },
          z '.icon',
            z $icon,
              icon: icon
              color: if isSelected then colors.$primary500 else colors.$white54
              isTouchTarget: false
          z '.text', text
