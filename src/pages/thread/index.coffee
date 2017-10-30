z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/operator/switchMap'
require 'rxjs/add/operator/map'

Head = require '../../components/head'
Thread = require '../../components/thread'
Icon = require '../../components/icon'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ThreadPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData}) ->
    # allow reset beforeUnmount so stale thread doesn't show when loading new
    @thread = new RxBehaviorSubject null
    loadedThread = requests.switchMap ({route}) =>
      @model.thread.getById route.params.id
    gameKey = requests.map ({route}) ->
      route.params.gameKey or config.DEFAULT_GAME_KEY
    thread = RxObservable.merge @thread, loadedThread

    @$head = new Head({
      @model
      requests
      serverData
      meta: {
        title: 'Community thread'
        description: 'Community'
      }
    })
    @$thread = new Thread {@model, @router, thread, gameKey}

    @state = z.state
      windowSize: @model.window.getSize()

  renderHead: => @$head

  beforeUnmount: =>
    @thread.next {}

  render: =>
    {windowSize, $el} = @state.getValue()

    z '.p-thread', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$thread
