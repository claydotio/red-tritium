z = require 'zorium'
supportsWebP = window? and require 'supports-webp'
_map = require 'lodash/map'
_pick = require 'lodash/pick'
_truncate = require 'lodash/truncate'
_defaults = require 'lodash/defaults'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Icon = require '../icon'
Avatar = require '../avatar'
ConversationImageView = require '../conversation_image_view'
ConversationInput = require '../conversation_input'
FormattedText = require '../formatted_text'
ThreadVoteButton = require '../thread_vote_button'
FormatService = require '../../services/format'
DateService = require '../../services/date'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

TITLE_LENGTH = 30
MAX_COMMENT_DEPTH = 3

module.exports = class ThreadComment
  constructor: (options) ->
    {@threadComment, @depth, @isMe, @model, @overlay$,
      @selectedProfileDialogUser, @router, @commentStreams,
      groupId} = options

    @depth ?= 0

    @$avatar = new Avatar()
    @$upvoteButton = new ThreadVoteButton {@model}
    @$downvoteButton = new ThreadVoteButton {@model}
    @$threadReplyIcon = new Icon()
    @$trophyIcon = new Icon()
    @$starIcon = new Icon()

    @imageData = new RxBehaviorSubject null
    @$conversationImageView = new ConversationImageView {
      @model
      @imageData
      @overlay$
      @router
    }

    @reply = new RxBehaviorSubject null
    @isPostLoading = new RxBehaviorSubject null

    @$children = _map @threadComment.children, (childThreadComment) =>
      new ThreadComment {
        threadComment: childThreadComment
        depth: @depth + 1
        @isMe, @model, @overlay$, @selectedProfileDialogUser, @router
      }

    @state = z.state
      me: @model.user.getMe()
      depth: @depth
      threadComment: @threadComment
      $children: @$children
      $body: new FormattedText {text: @threadComment.body, @model, @router}
      isMe: @isMe
      isReplyVisible: false
      isPostLoading: @isPostLoading
      groupId: groupId
      windowSize: @model.window.getSize()

  # for cached components
  setThreadComment: (threadComment) =>
    @state.set threadComment: threadComment
    isChildUpdated = _map threadComment.children, (child, i) =>
      if child.body isnt @theadComment?.children[i]?.body
        @$children[i] ?= new ThreadComment {
          threadComment: child
          depth: @depth + 1
          @isMe, @model, @overlay$, @selectedProfileDialogUser, @router
        }
        @$children[i].setThreadComment child

    if threadComment.body isnt @threadComment.body
      @threadComment = threadComment
      @state.set
        $body: new FormattedText {text: threadComment.body, @model, @router}


  postReply: =>
    {me, isPostLoading, threadComment} = @state.getValue()

    if isPostLoading
      return

    body = @reply.getValue()
    @isPostLoading.next true

    @model.signInDialog.openIfGuest me
    .then =>
      @model.threadComment.create {
        body: body
        threadId: threadComment.threadId
        parentId: threadComment.id
        parentType: 'threadComment'
      }
      .then =>
        @isPostLoading.next false
        @state.set isReplyVisible: false
      .catch =>
        @isPostLoading.next false

  render: =>
    {depth, isMe, threadComment, isReplyVisible, $body, groupId,
      windowSize, $children} = @state.getValue()

    {creator, time, card, body, id, clientId} = threadComment

    isSticker = body.match /^:[a-z_\^0-9]+:$/
    hasVotedUp = threadComment?.myVote?.vote is 1
    hasVotedDown = threadComment?.myVote?.vote is -1

    # pass these when voting so we can update scylla properly (no index on id)
    voteParent = _pick threadComment, [
      'id', 'threadId', 'creatorId', 'parentId', 'parentType',
      'timeUuid', 'timeBucket'
    ]
    voteParent.topId = threadComment.threadId
    voteParent.type = 'threadComment'

    onclick = =>
      @selectedProfileDialogUser.next _defaults {
        onDeleteMessage: =>
          @model.threadComment.deleteByThreadComment voteParent, {groupId}
          .then =>
            @commentStreams.take(1).toPromise()
      }, creator

    z '.z-thread-comment', {
      # re-use elements in v-dom
      key: "thread-comment-#{clientId or id}"
      className: z.classKebab {isSticker, isMe}
    },
      z '.comment',
        z '.avatar', {
          onclick
          style:
            width: '20px'
        },
          z @$avatar, {
            user: creator
            size: '20px'
            bgColor: colors.$grey200
          }

        z '.content',
          z '.author', {onclick},
            z '.name', @model.user.getDisplayName creator
            if creator?.flags?.isStar
              z '.icon',
                z @$starIcon,
                  icon: 'star-tag'
                  color: colors.$white
                  isTouchTarget: false
                  size: '22px'
            if creator?.gameData
              [
                z 'span', innerHTML: '&nbsp;&middot;&nbsp;'
                z '.trophies',
                  FormatService.number creator?.gameData?.data?.trophies
                  z '.icon',
                    z @$trophyIcon,
                      icon: 'trophy'
                      color: colors.$white54
                      isTouchTarget: false
                      size: '16px'
              ]
            z 'span', innerHTML: '&nbsp;&middot;&nbsp;'
            z '.time',
              if time
              then DateService.fromNow time
              else '...'


          z '.body', $body

          if card
            z '.card', {
              onclick: (e) =>
                e?.stopPropagation()
                @model.portal.call 'browser.openWindow', {
                  url: card.url
                  target: '_system'
                }
            },
              z '.title', _truncate card.title, {length: TITLE_LENGTH}
              z '.description', _truncate card.description, {
                length: DESCRIPTION_LENGTH
              }

          z '.bottom',
            z '.actions',
              if depth < MAX_COMMENT_DEPTH
                z '.reply', {
                  onclick: (e) =>
                    e?.stopPropagation()
                    if isReplyVisible
                      @state.set isReplyVisible: false
                    else
                      @$conversationInput = new ConversationInput {
                        @model
                        @router
                        message: @reply
                        @overlay$
                        @isPostLoading
                        onPost: @postReply
                        onResize: -> null
                      }
                      @state.set isReplyVisible: true
                },
                  @model.l.get 'general.reply'
                  # z @$threadReplyIcon,
                  #   icon: 'reply'
                  #   isTouchTarget: false
                  #   color: colors.$white
              z '.points',
                z '.icon',
                  z @$upvoteButton, {
                    vote: 'up'
                    hasVoted: hasVotedUp
                    parent: voteParent
                    isTouchTarget: false
                    color: colors.$tertiary300
                    size: '14px'
                  }

                threadComment.upvotes or 0

                z '.icon',
                  z @$downvoteButton, {
                    vote: 'down'
                    hasVoted: hasVotedDown
                    parent: voteParent
                    isTouchTarget: false
                    color: colors.$tertiary300
                    size: '14px'
                  }
      if isReplyVisible
        z '.reply',
          @$conversationInput

      z '.children',
        @$children
