z = require 'zorium'

if window?
  require './index.styl'

config = require '../../config'
colors = require '../../colors'

DEFAULT_WIDTH = 80
DEFAULT_HEIGHT = 96

module.exports = class Card
  constructor: ({@card}) -> null

  render: ({width, onclick} = {}) =>
    card = @card

    width ?= DEFAULT_WIDTH
    height = width * (DEFAULT_HEIGHT / DEFAULT_WIDTH)
    cdnUrl = config.CDN_URL

    cardId = card.key or card.cardId

    size = if width <= 24 then 'tiny' else 'small'
    bgUrl = if card then "#{cdnUrl}/cards/#{cardId}_#{size}.png?1" else ''

    z '.z-card', {
      onclick: ->
        onclick? card
      key: card?.id
      style:
        width: "#{width}px"
        height: "#{height}px"
        backgroundImage: if card and cardId \
                         then "url(#{bgUrl})"
                         else null
        backgroundColor: if card and cardId then null else colors.$black

    }
