z = require 'zorium'
Environment = require '../../services/environment'

PlayerList = require '../player_list'
SearchInput = require '../search_input'
AdsenseAd = require '../adsense_ad'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlayersTop
  constructor: ({@model, @router, @selectedProfileDialogUser}) ->
    @$searchInput = new SearchInput {@model}
    @$adsenseAd = new AdsenseAd {@model}

    @$playerList = new PlayerList {
      @model
      @router
      @selectedProfileDialogUser
      players: @model.player.getTop()
    }

  render: =>
    z '.z-players-top',
      z '.g-grid',
        z '.search',
          z @$searchInput, {
            isSearchIconRight: true
            height: '36px'
            bgColor: colors.$tertiary500
            onclick: =>
              @router.go 'playersSearch'
            placeholder: @model.l.get 'playersSearchPage.title'
          }

        if Environment.isMobile() and not Environment.isNativeApp(config.GAME_KEY)
          z '.ad',
            z @$adsenseAd, {
              slot: 'mobile300x250'
            }
        else if not Environment.isMobile()
          z '.ad',
            z @$adsenseAd, {
              slot: 'desktop728x90'
            }

        z '.subhead', @model.l.get 'playersPage.playersTop'
        z @$playerList, {
          onclick: ({player}) =>
            userId = player?.userId
            @router.go 'userById', {id: userId}
        }
