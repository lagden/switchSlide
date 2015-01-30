###
switch.js - SwitchSlide

It is a plugin that show `radios buttons` like switch slide

@author      Thiago Lagden <lagden [at] gmail.com>
@copyright   Author
###

((root, factory) ->
  if typeof define is 'function' and define.amd
    define [
      'get-style-property/get-style-property'
      'classie/classie'
      'eventEmitter/EventEmitter'
      'hammerjs/hammer'
    ], factory
  else
    root.SwitchSlide = factory root.getStyleProperty,
                               root.classie,
                               root.EventEmitter,
                               root.Hammer
  return
) @, (getStyleProperty, classie, EventEmitter, Hammer) ->

  'use strict'

  # Body
  docBody = document.querySelector 'body'

  # Extend object
  # https://github.com/desandro/draggabilly/blob/master/draggabilly.js#L17
  extend = (a, b) ->
    a[prop] = b[prop] for prop of b
    return a

  # Verify if object is an HTMLElement
  # http://stackoverflow.com/a/384380/182183
  isElement = (obj) ->
    if typeof HTMLElement is 'object'
      return obj instanceof HTMLElement
    else
      return obj and
             typeof obj is 'object' and
             obj.nodeType is 1 and
             typeof obj.nodeName is 'string'

  # Remove all children
  removeAllChildren = (el) ->
    while el.hasChildNodes()
      c = el.lastChild
      if c.hasChildNodes()
        el.removeChild removeAllChildren(c)
      else
        el.removeChild c
    return el

  # Transform property cross-browser
  transformProperty = getStyleProperty 'transform'

  # Globally unique identifiers
  GUID = 0

  # Internal store of all SwitchSlide intances
  instances = {}

  # Exception
  class SwitchSlideException
    constructor: (@message, @name='SwitchSlideException') ->

  # Vars
  #
  # @container
  # @options
  # @a
  # @b
  # @radios
  # @width
  # @margin
  # @shift
  # @valor
  # @active
  # @transformTranslateX
  # @keyCodes
  # @aria
  # @eventToggleParams
  # @eventChange
  # @widget
  # @sMin
  # @sMax
  # @knob
  # @sizes
  # @tapElement
  # @dragElement
  # @events
  # @hammer

  # Class
  class SwitchSlide

    # Private Methods
    _SPL =
      # Template
      getTemplate: ->
        return '
          <div class="{widget}">
            <div class="{opts} {optMin}">
              <span>{captionMin}</span>
            </div>
            <div class="{knob}"></div>
            <div class="{opts} {optMax}">
              <span>{captionMax}</span>
            </div>
          </div>'.trim()

      # Size of elements
      getSizes: (container, css) ->
        clone = container.cloneNode true
        clone.style.visibility = 'hidden'
        clone.style.position   = 'absolute'

        docBody.appendChild clone

        widget = clone.querySelector ".#{css.widget}"
        sMin   = widget.querySelector ".#{css.optMin}"
        sMax   = widget.querySelector ".#{css.optMax}"
        knob   = widget.querySelector ".#{css.knob}"

        knobComputedStyle = window.getComputedStyle knob
        knobMarLeft  = parseInt knobComputedStyle.marginLeft, 10
        knobMarRight = parseInt knobComputedStyle.marginRight, 10

        sizes =
          'sMin': sMin.clientWidth
          'sMax': sMax.clientWidth
          'knob': knob.clientWidth
          'margin': knobMarLeft + knobMarRight
          'max' : Math.max sMin.clientWidth, sMax.clientWidth

        # Remove
        docBody.removeChild removeAllChildren(clone)

        # GC
        clone  = null
        widget = null
        sMin   = null
        sMax   = null
        knob   = null
        return sizes

      # Event handler
      #
      onToggle: ->
        width = if @options.negative then -@width else @width
        opts = [
          @sMin
          @sMax
        ]

        if @shift isnt null
          @active = true
          @transformTranslateX = if @shift then width else 0

          a = if @shift then @b else @a
          b = a ^ 1

          c = if @options.swapOrder then a else b
          d = c ^ 1

          _SPL.checked @radios[a], opts[c]
          _SPL.unchecked @radios[b], opts[d]

        else
          @active = false
          @transformTranslateX = width / 2
          _SPL.unchecked @radios[num], opts[num] for num in [0..1]

        _SPL.isActive.call @

        @updateAria()
        @updateValor()
        @updatePosition()
        @emitToggle()

        for radio in @radios when radio.checked
          radio.dispatchEvent @eventChange
          radio.dispatchEvent @eventClick

        width =
        a     =
        b     = null
        return

      onStart: (event) ->
        @dragElement.focus()
        classie.add @dragElement, 'is-dragging'
        return

      onMove: (event) ->
        width = if @options.negative then -@width else @width
        v = (width / 2) + event.deltaX

        if @shift isnt null
          v = if @shift then width + event.deltaX else event.deltaX

        if @options.negative
          @transformTranslateX = Math.min 0, Math.max width, v
        else
          @transformTranslateX = Math.min width, Math.max v, 0

        @updatePosition()

        width =
        v     = null
        return

      onEnd: (event) ->
        @shift = Math.abs(@transformTranslateX) > (@width / 2)
        classie.remove @dragElement, 'is-dragging'
        _SPL.onToggle.call @
        return

      onTap: (event) ->
        rect = @tapElement.getBoundingClientRect()
        data = [
          rect.left + (rect.width / 2)
          event.center.x
        ]
        a = if @options.negative then 1 else 0
        b = a ^ 1

        @shift = data[a] < data[b]

        _SPL.onToggle.call @

        rect =
        data =
        a    =
        b    = null
        return

      onKeydown: (event) ->
        trigger = true
        switch event.keyCode
          when @keyCodes.space
            @shift = !@shift
          when @keyCodes.right
            @shift = !@options.negative
          when @keyCodes.left
            @shift = @options.negative
          else
            trigger = false

        _SPL.onToggle.call @ if trigger

        trigger = null
        return

      # Helpers
      #
      # Check if widget is active
      isActive: ->
        if @active isnt null
          method = if @active then 'add' else 'remove'
          classie[method] @knob, 'is-active'
          classie[method] @widget, 'is-active'
          classie.remove @widget, @options.errorClass if @active
        return

      # Get Elements
      getElements: ->
        @widget = @container.querySelector ".#{@css.widget}"
        @sMin   = @widget.querySelector ".#{@css.optMax}"
        @sMax   = @widget.querySelector ".#{@css.optMin}"
        @knob   = @widget.querySelector ".#{@css.knob}"
        return

      # Set Widths
      setSizes: ->
        @sMin.style.width = "#{@width}px"
        @sMax.style.width = "#{@width}px"
        @knob.style.width = "#{@width - @margin}px"
        @container.style.width = (@width * 2)  + 'px'
        return

      # Handler Tap
      getTapElement: ->
        return @widget

      # Handler Drag
      getDragElement: ->
        return @knob

      # Radio checked
      checked: (radio, opt) ->
        radio.setAttribute 'checked', ''
        radio.checked = true
        if opt?
          classie.add opt, 'selected'
        return

      # Radio unchecked
      unchecked: (radio, opt) ->
        radio.removeAttribute 'checked'
        radio.checked = false
        if opt?
          classie.remove opt, 'selected'
        return

      # Observer
      observer: (radio) ->
        has = classie.has radio, @option.observerClass
        method = if has then 'add' else 'remove'
        classie[method] @widget, @options.errorClass
        return

      # Build
      build: ->
        # Caption
        captionMin = captionMax = ''

        labels = @container.getElementsByTagName 'label'
        if labels.length == 2
          captionMin  = labels[@a].textContent
          captionMax  = labels[@b].textContent
        else
          console.warn '✖ No labels'

        # Template Render
        r =
          'captionMin' : captionMin
          'captionMax' : captionMax
          'widget'     : @options.widget
          'opts'       : @options.opts
          'optMin'     : @options.optMin
          'optMax'     : @options.optMax
          'knob'       : @options.knob

        content = @options.template().replace /\{(.*?)\}/g, (a, b) ->
          return r[b]

        @container.insertAdjacentHTML 'afterbegin', content

        labels     =
        captionMin =
        captionMax =
        content    = null

        # Elements
        @options.getElements.call @

        # Size
        @sizes  = _SPL.getSizes @container, @css
        @width  = @sizes.max
        @margin = @sizes.margin
        @options.setSizes.call @

        # WAI-ARIA
        @widget.setAttribute attrib, value for attrib, value of @aria

        # Handlers
        @tapElement  = @options.getTapElement.call @
        @dragElement = @options.getDragElement.call @

        # Events
        @events =
          tap       : _SPL.onTap.bind @
          panstart  : _SPL.onStart.bind @
          pan       : _SPL.onMove.bind @
          panend    : _SPL.onEnd.bind @
          pancancel : _SPL.onEnd.bind @
          keydown   : _SPL.onKeydown.bind @

        # Hammer Management
        @hammer = [
          {
            manager : new Hammer.Manager @tapElement
            evento  : new Hammer.Tap
            methods : [
              'tap'
            ]
          }
          {
            manager : new Hammer.Manager @dragElement,
                                         dragLockToAxis: true
                                         dragBlockHorizontal: true
                                         preventDefault: true
            evento  : new Hammer.Pan direction: Hammer.DIRECTION_HORIZONTAL
            methods : [
              'panstart'
              'pan'
              'panend'
              'pancancel'
            ]
          }
        ]

        # Add Event and Handler
        for o in @hammer
          o.manager.add o.evento
          for m in o.methods
            o.manager.on m, @events[m]

        @widget.addEventListener 'keydown', @events.keydown, true

        # Observer
        hasMutation = `'MutationObserver' in window`
        if hasMutation AND @option.observerClass
          that = @
          observer = new MutationObserver (mutations) ->
            mutations.forEach (mutation) ->
              if mutation.attributeName == 'class'
                _SPL.observer.apply that, [mutation.target]
              return
            return

          configObserver =
            attributes: true
            attributeOldValue: true

          for radio in @radios
            observer.observe radio, configObserver

        # Init
        _SPL.onToggle.call @
        return

    constructor: (container, options) ->

      # Self instance
      if false is (@ instanceof SwitchSlide)
        return new SwitchSlide container, options

      # Container
      if typeof container == 'string'
        @container = document.querySelector container
      else
        @container = container

      # Exception
      if isElement @container is false
        throw new SwitchSlideException '✖ Container must be an HTMLElement'
      else
        # Check if component was initialized
        initialized = SwitchSlide.data @container

        if initialized instanceof SwitchSlide
          return initialized
        else
          id = ++GUID

          @container.GUID = id
          instances[id] = @

          # Options
          @options =
            labeledby      : null
            required       : false
            template       : _SPL.getTemplate
            setSizes       : _SPL.setSizes
            getElements    : _SPL.getElements
            getTapElement  : _SPL.getTapElement
            getDragElement : _SPL.getDragElement
            negative       : false
            swapOrder      : false
            errorClass     : 'widgetSlide_err'
            observerClass  : null
            initialize     : ''
            widget         : ''
            opts           : ''
            optMin         : ''
            optMax         : ''
            knob           : ''

          extend @options, options

          @css =
            initialize : 'switchSlide--initialized'
            widget     : 'widgetSlide'
            opts       : 'widgetSlide__opt'
            optMin     : 'widgetSlide__opt--min'
            optMax     : 'widgetSlide__opt--max'
            knob       : 'widgetSlide__knob'

          for k, v of @css
            @options[k] = "#{v} #{@options[k]}".trim()

          # Order
          @a = if @options.swapOrder then 1 else 0
          @b = @a ^ 1

          # Radios
          @radios = []
          radios = @container.getElementsByTagName 'input'
          for radio, idx in radios when radio.type == 'radio'
            # if @options.required
            #   radio.setAttribute 'required', ''
            @radios.push radio

          # Exception
          if @radios.length != 2
            throw new SwitchSlideException '✖ No radios'
          else
            # Initialize
            for css in @options.initialize.split(' ')
              classie.add @container, css

            # Width
            @width = 0
            @margin = 0

            # on, off or null
            @shift = null
            @shift = off if @radios[@a].checked
            @shift = on  if @radios[@b].checked

            # Initial value
            @valor = null
            @updateValor()

            # Active - Show elements when a side is selected
            @active = null

            # Animation
            @transformTranslateX = 0

            # Keyboard
            @keyCodes =
              'space' : 32
              'left'  : 37
              'right' : 39

            # Accessibility
            @aria =
              'tabindex'       : 0
              'role'           : 'slider'
              'aria-valuemin'  : @radios[@a].value
              'aria-valuemax'  : @radios[@b].value
              'aria-valuetext' : null
              'aria-valuenow'  : null
              'aria-labeledby' : @options.labeledby
              'aria-required'  : @options.required

            # Event parameters
            @eventToggleParams = [
              'instance' : @
              'radios'   : @radios
              'value'    : @valor
            ]

            # Events
            @eventChange = new CustomEvent 'change', bubbles: true
            @eventClick  = new CustomEvent 'click', bubbles: true

            # Others
            @widget =
            @sMin   =
            @sMax   =
            @knob   = null

            _SPL.build.call @

      return

    # Trigger
    emitToggle: ->
      @.emitEvent 'toggle', @eventToggleParams
      return

    # Swap
    swap: (v) ->
      @shift = if v? then v else !@shift
      _SPL.onToggle.call @
      return

    # Reset
    reset: ->
      @shift = null
      _SPL.onToggle.call @
      return

    # Update WAI-ARIA - Accessibility
    updateAria: ->
      if @shift isnt null
        v = if @shift is on then @radios[@b].title else @radios[@a].title
        @widget.setAttribute 'aria-valuenow', @valor
        @widget.setAttribute 'aria-valuetext', v
      v = null
      return

    # Update value
    updateValor: ->
      @valor = null
      if @shift isnt null
        @valor = if @shift is on then @radios[@b].value else @radios[@a].value

      if @eventToggleParams?
        @eventToggleParams[0].value = @valor
      return

    # Update position
    updatePosition: ->
      value = ["translate3d(#{@transformTranslateX}px, 0, 0)"]
      @dragElement.style[transformProperty] = value.join " "
      value = null
      return

    # Destroy
    destroy: ->
      if @container isnt null

        # Remove Listeners
        for o in @hammer
          o.manager.destroy()

        @widget.removeEventListener 'keydown', @events.keydown

        # Remove children from @widget
        removeAllChildren @widget

        # Remove @widget
        if @container.contains @widget
          @container.removeChild @widget

        # Remove classes and attributes
        for css in @options.initialize.split(' ')
          classie.remove @container, css
        @container.removeAttribute 'style'

        # Remove reference
        @container.GUID = null

        # Nullable
        @container           =
        @options             =
        @a                   =
        @b                   =
        @radios              =
        @width               =
        @margin              =
        @shift               =
        @valor               =
        @active              =
        @transformTranslateX =
        @keyCodes            =
        @aria                =
        @eventToggleParams   =
        @eventChange         =
        @widget              =
        @sMin                =
        @sMax                =
        @knob                =
        @sizes               =
        @tapElement          =
        @dragElement         =
        @events              =
        @hammer              = null
      return

  # Extends
  extend SwitchSlide::, EventEmitter::

  # https://github.com/metafizzy/outlayer/blob/master/outlayer.js#L887
  #
  # get SwitchSlide instance from element
  # @param {Element} el
  # @return {SwitchSlide}
  #
  SwitchSlide.data = (el) ->
    id = el and el.GUID
    return id and instances[id]

  return SwitchSlide
