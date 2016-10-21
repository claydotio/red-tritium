z = require 'zorium'
Rx = require 'rx-lite'
_ = require 'lodash'
_map = require 'lodash/collection/map'
_mapValues = require 'lodash/object/mapValues'
_isEmpty = require 'lodash/lang/isEmpty'

config = require '../../config'
colors = require '../../colors'
Head = require '../../components/head'
AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
CardInfo = require '../../components/card_info'
Spinner = require '../../components/spinner'
Icon = require '../../components/icon'

if window?
  require './index.styl'

module.exports = class CardPage
  constructor: ({@model, requests, @router, serverData}) ->
    card = requests.flatMapLatest ({route}) =>
      @model.clashRoyaleCard.getById route.params.id

    @$head = new Head({
      @model
      requests
      serverData
      meta: {
        title: 'Card'
        description: 'Card'
      }
    })
    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$cardInfo = new CardInfo {@model, @router, card}

    @state = z.state {card}

  renderHead: => @$head

  render: =>
    {card} = @state.getValue()

    z '.p-card', {
      style:
        height: "#{window?.innerHeight}px"
    },
      z @$appBar, {
        title: card?.name
        $topLeftButton: z @$buttonBack, {color: colors.$primary900}
        isFlat: true
      }
      @$cardInfo