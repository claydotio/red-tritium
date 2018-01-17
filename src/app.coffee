z = require 'zorium'
HttpHash = require 'http-hash'
_forEach = require 'lodash/forEach'
_map = require 'lodash/map'
_values = require 'lodash/values'
_flatten = require 'lodash/flatten'
_defaults = require 'lodash/defaults'
Environment = require 'clay-environment'
isUuid = require 'isuuid'
RxObservable = require('rxjs/Observable').Observable
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
require 'rxjs/add/operator/map'
require 'rxjs/add/operator/filter'
require 'rxjs/add/operator/switchMap'
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
require 'rxjs/add/operator/publishReplay'

Drawer = require './components/drawer'
BottomBar = require './components/bottom_bar'
XpGain = require './components/xp_gain'
SignInDialog = require './components/sign_in_dialog'
InstallOverlay = require './components/install_overlay'
GetAppDialog = require './components/get_app_dialog'
AddToHomeScreenSheet = require './components/add_to_home_sheet'
PushNotificationsSheet = require './components/push_notifications_sheet'
ConversationImageView = require './components/conversation_image_view'
OfflineOverlay = require './components/offline_overlay'
Nps = require './components/nps'
config = require './config'

Pages =
  HomePage: require './pages/home'
  FriendsPage: require './pages/friends'
  ToolPage: require './pages/addon'
  ConversationPage: require './pages/conversation'
  ConversationsPage: require './pages/conversations'
  NewConversationPage: require './pages/new_conversation'
  # GroupPage: require './pages/group'
  GroupChatPage: require './pages/group_chat'
  GroupCollectionPage: require './pages/group_collection'
  GroupForumPage: require './pages/group_forum'
  GroupHomePage: require './pages/group_home'
  GroupMembersPage: require './pages/group_members'
  GroupSettingsPage: require './pages/group_settings'
  GroupShopPage: require './pages/group_shop'
  GroupInvitesPage: require './pages/group_invites'
  GroupInvitePage: require './pages/group_invite'
  GroupAddRecordsPage: require './pages/group_add_records'
  GroupBannedUsersPage: require './pages/group_banned_users'
  GroupManageRolesPage: require './pages/group_manage_roles'
  GroupAuditLogPage: require './pages/group_audit_log'
  GroupManageChannelsPage: require './pages/group_manage_channels'
  GroupAddChannelPage: require './pages/group_add_channel'
  GroupEditChannelPage: require './pages/group_edit_channel'
  GroupManageMemberPage: require './pages/group_manage_member'
  GroupVideosPage: require './pages/group_videos'
  GroupLeaderboardPage: require './pages/group_leaderboard'
  GroupProfilePage: require './pages/group_profile'
  GroupToolsPage: require './pages/group_addons'
  EditThreadPage: require './pages/edit_thread'
  ThreadPage: require './pages/thread'
  NewThreadPage: require './pages/new_thread'
  PlayersSearchPage: require './pages/players_search'
  ProfileChestsPage: require './pages/profile_chests'
  # TODO: rename groups
  # SocialPage: require './pages/social'
  TosPage: require './pages/tos'
  UserOfWeekPage: require './pages/user_of_week'
  PoliciesPage: require './pages/policies'
  PrivacyPage: require './pages/privacy'
  EditProfilePage: require './pages/edit_profile'
  FourOhFourPage: require './pages/404'

TIME_UNTIL_ADD_TO_HOME_PROMPT_MS = 90000 # 1.5 min

module.exports = class App
  constructor: (options) ->
    {requests, @serverData, @model, @router, isOffline} = options
    @$cachedPages = []
    routes = @model.window.getBreakpoint().map @getRoutes
            .publishReplay(1).refCount()

    requestsAndRoutes = RxObservable.combineLatest(
      requests, routes, (vals...) -> vals
    )

    isFirstRequest = true
    @requests = requestsAndRoutes.map ([req, routes]) =>
      userAgent = navigator?.userAgent or req.headers?['user-agent']
      if isFirstRequest and Environment.isGameApp(config.GAME_KEY, {userAgent})
        path = @model.cookie.get('lastPath') or req.path
        if window?
          req.path = path # doesn't work server-side
        else
          req = _defaults {path}, req
      route = routes.get req.path
      $page = route.handler?()
      isFirstRequest = false
      {req, route, $page: $page}
    .publishReplay(1).refCount()

    requestsAndLanguage = RxObservable.combineLatest(
      @requests, @model.l.getLanguage(), (vals...) -> vals
    )

    @group = requestsAndLanguage.switchMap ([{$page, route}, language]) =>
      isGroup = $page?.isGroup
      groupId = route.params.groupId or @model.cookie.get 'lastGroupId'
      if isGroup and isUuid groupId
        @model.cookie.set 'lastGroupId', groupId
        @model.group.getById groupId
      else if isGroup and groupId
        @model.cookie.set 'lastGroupId', groupId
        @model.group.getByKey groupId
      else
        @model.group.getByGameKeyAndLanguage(
          config.DEFAULT_GAME_KEY, language
        )

    # used if state / requests fails to work
    $backupPage = if @serverData?
      userAgent = @serverData.req.headers?['user-agent']
      if Environment.isGameApp config.GAME_KEY, {userAgent}
        serverPath = @model.cookie.get('lastPath') or @serverData.req.path
      else
        serverPath = @serverData.req.path
      @getRoutes().get(serverPath).handler?()
    else
      null

    addToHomeSheetIsVisible = new RxBehaviorSubject false

    # TODO: have all other component overlays use this
    @overlay$ = new RxBehaviorSubject null

    @$offlineOverlay = new OfflineOverlay {@model, isOffline}
    @$drawer = new Drawer {@model, @router, @group, @overlay$}
    @$xpGain = new XpGain {@model}
    @$signInDialog = new SignInDialog {@model, @router}
    @$getAppDialog = new GetAppDialog {@model, @router}
    @$installOverlay = new InstallOverlay {@model, @router}
    @$conversationImageView = new ConversationImageView {@model, @router}
    @$addToHomeSheet = new AddToHomeScreenSheet {
      @model
      @router
      isVisible: addToHomeSheetIsVisible
    }
    @$pushNotificationsSheet = new PushNotificationsSheet {@model, @router}
    @$bottomBar = new BottomBar {@model, @router, @requests, @group}

    @$nps = new Nps {@model}

    me = @model.user.getMe()

    if localStorage? and not localStorage['lastAddToHomePromptTime']
      setTimeout ->
        isNative = Environment.isGameApp(config.GAME_KEY)
        if not isNative and not localStorage['lastAddToHomePromptTime']
          addToHomeSheetIsVisible.next true
          localStorage['lastAddToHomePromptTime'] = Date.now()
      , TIME_UNTIL_ADD_TO_HOME_PROMPT_MS

    @state = z.state {
      $backupPage: $backupPage
      me: me
      $overlay: @overlay$
      isOffline: isOffline
      addToHomeSheetIsVisible: addToHomeSheetIsVisible
      signInDialogIsOpen: @model.signInDialog.isOpen()
      signInDialogMode: @model.signInDialog.getMode()
      getAppDialogIsOpen: @model.getAppDialog.isOpen()
      pushNotificationSheetIsOpen: @model.pushNotificationSheet.isOpen()
      installOverlayIsOpen: @model.installOverlay.isOpen()
      imageViewOverlayImageData: @model.imageViewOverlay.getImageData()
      hideDrawer: @requests.switchMap (request) ->
        hideDrawer = request.$page?.hideDrawer
        if hideDrawer?.map
        then hideDrawer
        else RxObservable.of (hideDrawer or false)
      request: @requests.do ({$page, req}) ->
        if $page instanceof Pages['FourOhFourPage']
          res?.status? 404
    }

  getRoutes: (breakpoint) =>
    # can have breakpoint (mobile/desktop) specific routes
    routes = new HttpHash()
    languages = @model.l.getAllUrlLanguages()

    route = (routeKeys, pageKey, isGamePath) =>
      Page = Pages[pageKey]
      if typeof routeKeys is 'string'
        routeKeys = [routeKeys]

      paths = _flatten _map routeKeys, (routeKey) =>
        # if routeKey is '404'
        #   return _map languages, (lang) ->
        #     if lang is 'en' then '/:gameKey/*' else "/#{lang}/:gameKey/*"
        _values @model.l.getAllPathsByRouteKey routeKey, isGamePath

      _map paths, (path) =>
        routes.set path, =>
          unless @$cachedPages[pageKey]
            @$cachedPages[pageKey] = new Page({
              @model
              @router
              @serverData
              @overlay$
              @group
              $bottomBar: if Page.hasBottomBar then @$bottomBar
              requests: @requests.filter ({$page}) ->
                $page instanceof Page
            })
          return @$cachedPages[pageKey]

    routeGame = (routeKeys, pageKey) ->
      route routeKeys, pageKey, true

    routeGame ['friendsWithAction', 'friends'], 'FriendsPage'
    routeGame ['tool', 'toolByKey'], 'ToolPage'
    routeGame 'conversation', 'ConversationPage'
    routeGame 'conversations', 'ConversationsPage'
    routeGame 'newConversation', 'NewConversationPage'
    routeGame ['thread', 'threadWithTitle'], 'ThreadPage'
    routeGame 'threadEdit', 'EditThreadPage'
    routeGame 'group', 'GroupChatPage'
    routeGame 'groupChat', 'GroupChatPage'
    routeGame 'groupCollection', 'GroupCollectionPage'
    routeGame 'groupForum', 'GroupForumPage'
    routeGame 'groupHome', 'GroupHomePage'
    routeGame 'groupMembers', 'GroupMembersPage'
    routeGame 'groupChatConversation', 'GroupChatPage'
    routeGame 'groupInvite', 'GroupInvitePage'
    routeGame 'groupInvites', 'GroupInvitesPage'
    routeGame 'groupShop', 'GroupShopPage'
    routeGame 'groupTools', 'GroupToolsPage'
    routeGame 'groupManage', 'GroupManageMemberPage'
    routeGame 'groupManageChannels', 'GroupManageChannelsPage'
    routeGame 'groupNewChannel', 'GroupAddChannelPage'
    routeGame 'groupEditChannel', 'GroupEditChannelPage'
    routeGame 'groupSettings', 'GroupSettingsPage'
    routeGame 'groupVideos', 'GroupVideosPage'
    routeGame 'groupLeaderboard', 'GroupLeaderboardPage'
    routeGame 'groupAddRecords', 'GroupAddRecordsPage'
    routeGame 'groupBannedUsers', 'GroupBannedUsersPage'
    routeGame 'groupManageRoles', 'GroupManageRolesPage'
    routeGame 'groupAuditLog', 'GroupAuditLogPage'
    routeGame [
      'newThread', 'newThreadWithCategory', 'newThreadWithCategoryAndId'
    ], 'NewThreadPage'
    routeGame 'playersSearch', 'PlayersSearchPage'
    routeGame 'policies', 'PoliciesPage'
    routeGame 'star', 'StarPage'
    routeGame 'stars', 'StarsPage'
    routeGame 'termsOfService', 'TosPage'
    routeGame 'userOfWeek', 'UserOfWeekPage'
    routeGame 'privacy', 'PrivacyPage'
    routeGame [
      'profile', 'clashRoyalePlayer', 'playerEmbed', 'user', 'userById'
      'groupProfile'
    ], 'GroupProfilePage'
    routeGame [
      'chestCycleByPlayerId', 'chestCycleByPlayerIdEmbed'
    ], 'ProfileChestsPage'
    routeGame 'editProfile', 'EditProfilePage'

    route ['home', 'siteHome'], 'GroupHomePage'
    route '404', 'FourOhFourPage'
    routes

  render: =>
    {request, $backupPage, $modal, me, imageViewOverlayImageData, hideDrawer
      installOverlayIsOpen, signInDialogIsOpen, signInDialogMode,
      pushNotificationSheetIsOpen, getAppDialogIsOpen,
      addToHomeSheetIsVisible, $overlay, isOffline} = @state.getValue()

    userAgent = request?.req?.headers?['user-agent'] or
      navigator?.userAgent or ''
    isIos = /iPad|iPhone|iPod/.test userAgent
    isNative = Environment.isGameApp(config.GAME_KEY)
    isPageAvailable = (me?.isMember or not request?.$page?.isPrivate)
    defaultInstallMessage = @model.l.get 'app.defaultInstallMessage'

    z 'html',
      request?.$page?.renderHead() or $backupPage?.renderHead()
      z 'body',
        z '#zorium-root', {
          className: z.classKebab {isIos}
        },
          # z '.warning', {
          #   style:
          #     textAlign: 'center'
          # }
          #   'We\'re working on bring back up all features'
          z '.z-root',
            unless hideDrawer
              z @$drawer, {currentPath: request?.req.path}
            z '.page',
              # show page before me has loaded
              if (not me or isPageAvailable) and request?.$page
                request.$page
              else
                $backupPage

            if signInDialogIsOpen
              z @$signInDialog, {mode: signInDialogMode}
            if getAppDialogIsOpen
              z @$getAppDialog
            if installOverlayIsOpen
              z @$installOverlay
            if imageViewOverlayImageData
              z @$conversationImageView
            if addToHomeSheetIsVisible
              z @$addToHomeSheet, {
                message: request?.$page?.installMessage or defaultInstallMessage
              }
            if pushNotificationSheetIsOpen
              z @$pushNotificationsSheet
            if isOffline
              z @$offlineOverlay
            if @$nps.shouldBeShown()
              z @$nps,
                gameName: 'Starfire'
                onRate: =>
                  @model.portal.call 'app.rate'
            if $overlay
              # can be array of components or component
              z $overlay
            if not window?
              z '#server-loading', {
                key: 'server-loading'
                attributes:
                  onmousedown: "document.getElementById('server-loading')" +
                    ".classList.add('is-clicked')"
                  ontouchstart: "document.getElementById('server-loading')" +
                    ".classList.add('is-clicked')"

              },
                @model.l.get 'app.stillLoading'
            z @$xpGain
