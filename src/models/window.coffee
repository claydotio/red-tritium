Environment = require 'clay-environment'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

CookieService = require '../services/cookie'
config = require '../config'

DRAWER_RIGHT_PADDING = 56
DRAWER_MAX_WIDTH = 336

module.exports = class Window
  constructor: ({@cookieSubject, @experiment}) ->
    @isPaused = false

    @size = new RxBehaviorSubject @getSizeVal()
    @breakpoint = new RxBehaviorSubject @getBreakpointVal()
    @drawerWidth = new RxBehaviorSubject @getDrawerWidthVal()
    @appBarHeight = new RxBehaviorSubject @getAppBarHeightVal()
    window?.addEventListener 'resize', @updateSize

  updateSize: =>
    unless @isPaused
      @size.next @getSizeVal()
      @breakpoint.next @getBreakpointVal()

  getSizeVal: =>
    resolution = CookieService.get @cookieSubject, 'resolution'
    if window?
      width = window.innerWidth
      height = window.innerHeight
    else if resolution
      arr = resolution.split 'x'
      width = arr[0]
      height = arr[1]
    else
      width = undefined
      height = 732

    {
      width: width
      height: height
    }

  getBreakpointVal: =>
    {width} = @getSizeVal()
    if width >= 1280
      'desktop'
    else
      'mobile'

  getDrawerWidthVal: =>
    {width} = @getSizeVal()
    Math.min(
      width - DRAWER_RIGHT_PADDING
      DRAWER_MAX_WIDTH
    )

  getAppBarHeightVal: =>
    {width} = @getSizeVal()
    if width > 768 then 64 else 56

  getSize: =>
    @size

  getDrawerWidth: =>
    @drawerWidth

  getBreakpoint: =>
    @breakpoint

  getAppBarHeight: =>
    @appBarHeight

  pauseResizing: =>
    @isPaused = true

  resumeResizing: =>
    @isPaused = false
    @updateSize()
