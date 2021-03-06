z = require 'zorium'

Tabs = require '../tabs'
Icon = require '../icon'
ProfileInfo = require '../clash_royale_profile_info'
ProfileDecks = require '../clash_royale_profile_decks'
ProfileMatches = require '../clash_royale_profile_matches'
ProfileGraphs = require '../clash_royale_profile_graphs'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class Profile
  constructor: (options) ->
    {@model, @router, user, player, @overlay$, group, serverData} = options
    me = @model.user.getMe()

    @$tabs = new Tabs {@model}
    @$infoIcon = new Icon()
    @$historyIcon = new Icon()
    @$decksIcon = new Icon()
    @$graphIcon = new Icon()

    @$profileInfo = new ProfileInfo {
      @model, @router, user, player, @overlay$, group, serverData
    }
    @$profileDecks = new ProfileDecks {
      @model, @router, user, player, group
    }
    @$profileMatches = new ProfileMatches {
      @model, @router, user, player, group
    }
    @$profileGraphs = new ProfileGraphs {
      @model, @router, user, player, group
    }

    @state = z.state
      me: me

  render: ({isOtherProfile} = {}) =>
    {me} = @state.getValue()

    z '.z-profile',
      z @$tabs,
        isBarFixed: false
        isBarFlat: false
        barStyle: 'primary'
        tabs: [
          {
            $menuIcon: @$infoIcon
            menuIconName: 'info'
            $menuText: @model.l.get 'general.info'
            $el: @$profileInfo
          }
          # {
          #   $menuIcon: @$historyIcon
          #   menuIconName: 'history'
          #   $menuText: 'Matches'
          #   $el: @$profileMatches
          # }
          {
            $menuIcon: @$decksIcon
            menuIconName: 'decks'
            $menuText: @model.l.get 'general.decks'
            $el: @$profileDecks
          }
          {
            $menuIcon: @$graphIcon
            menuIconName: 'stats'
            $menuText: @model.l.get 'general.graphs'
            $el: @$profileGraphs
          }
        ]
