###
switch.js - SwitchSlide

It is a plugin that show `radios buttons` like switch slide

@author      Thiago Lagden <lagden [at] gmail.com>
@copyright   Author
###

((root, factory) ->
  if typeof define is "function" and define.amd
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

  # Extend object
  extend = (a, b) ->
    a[prop] = b[prop] for prop of b
    return a

  # Transform property cross-browser
  transformProperty = getStyleProperty 'transform'

  # Globally unique identifiers
  GUID = 0

  # Internal store of all SwitchSlide intances
  instances = {}

  # Exception
  class SwitchSlideException
    constructor: (@message, @name='SwitchSlideException') ->

  # Private Methods
  _SPL =
    # Template
    getTemplate: ->
      return '<div class="widgetSlide">
        <div class="widgetSlide__opt widgetSlide__opt--min">
        <span>{captionMin}</span>
        </div>
        <div class="widgetSlide__knob"></div>
        <div class="widgetSlide__opt widgetSlide__opt--max">
        <span>{captionMax}</span>
        </div>'

    # Size of elements
    getSizes: ->
      clone = @container.cloneNode true
      clone.style.visibility = 'hidden'
      clone.style.position   = 'absolute'

      document.body.appendChild clone

      widget = clone.querySelector @options.selectors.widget
      sMin   = widget.querySelector @options.selectors.optMin
      sMax   = widget.querySelector @options.selectors.optMax
      knob   = widget.querySelector @options.selectors.knob

      sizes =
        'sMin': sMin.clientWidth
        'sMax': sMax.clientWidth
        'knob': knob.clientWidth
        'max' : Math.max sMin.clientWidth, sMax.clientWidth

      document.body.removeChild clone
      clone = null
      return sizes

    # Event handler
    #
    onToggle: ->
      width = if @options.negative then -@width else @width

      if @shift isnt null
        @active = true
        @transform.translate.x = if @shift then width else 0

        a = if @shift then 1 else 0
        b = a ^ 1

        _SPL.checked(@radios[a])
        _SPL.unchecked(@radios[b])

      else
        @active = false
        @transform.translate.x = width / 2
        _SPL.unchecked(radio) for radio in @radios

      @isActive()
      @updateAria()
      @updateValor()
      @updatePosition()

      @emitToggle()

      for radio in @radios when radio.checked
        radio.dispatchEvent @eventChange
      return

    onStart: (el, event) ->
      el.focus()
      classie.add el, 'is-dragging'
      return

    onMove: (event) ->
      width = if @options.negative then -@width else @width
      v = (width / 2) + event.deltaX

      if @shift isnt null
        v = if @shift then width + event.deltaX else event.deltaX

      if @options.negative
        @transform.translate.x = Math.min 0, Math.max width, v
      else
        @transform.translate.x = Math.min width, Math.max v, 0

      @updatePosition()
      return

    onEnd: (el, event) ->
      @shift = Math.abs(@transform.translate.x) > (@width / 2)
      classie.remove el, 'is-dragging'
      _SPL.onToggle.call(@)
      return

    onTap: (el, event) ->
      rect = el.getBoundingClientRect()
      data = [
        rect.left + (rect.width / 2)
        event.center.x
      ]
      a = if @options.negative then 1 else 0
      b = a ^ 1

      @shift = data[a] < data[b]

      _SPL.onToggle.call(@)
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

      _SPL.onToggle.call(@) if trigger
      return

    # Set Elements
    setElements: ->
      @widget = @container.querySelector @options.selectors.widget
      @sMin   = @widget.querySelector @options.selectors.optMax
      @sMax   = @widget.querySelector @options.selectors.optMin
      @knob   = @widget.querySelector @options.selectors.knob

    # Set Widths
    setSizes: ->
      @sMin.style.width = "#{@width}px"
      @sMax.style.width = "#{@width}px"
      @knob.style.width = "#{@width}px"
      @container.style.width = (@width * 2)  + 'px'

    # Listener Tap Event
    getTapElement: ->
      return @widget

    # Listener Drag Event
    getDragElement: ->
      return @knob

    # Radio checked
    checked: (radio) ->
      radio.setAttribute 'checked', ''
      radio.checked = true
      return

    # Radio unchecked
    unchecked: (radio) ->
      radio.removeAttribute 'checked'
      radio.checked = false
      return

    # Build widget
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

      content = @options.template.replace /\{(.*?)\}/g, (a, b) ->
        return r[b]

      @container.insertAdjacentHTML 'afterbegin', content

      # Elements and size
      @options.setElements.call(@)

      # Set widths
      @sizes = _SPL.getSizes.call(@)
      @width = @sizes.max
      @options.setSizes.call(@)

      # Aria
      @widget.setAttribute attrib, value for attrib, value of @aria

      # Tap Event
      tapElement = @options.getTapElement.call(@)
      tap = new Hammer.Tap
      @mc = new Hammer.Manager tapElement,
        dragLockToAxis: true
        dragBlockHorizontal: true
        preventDefault: true

      @mc.add tap
      @mc.on 'tap', _SPL.onTap.bind(@, tapElement)

      # Drag Event
      dragElement = @options.getDragElement.call(@)
      pan = new Hammer.Pan direction: Hammer.DIRECTION_HORIZONTAL
      @mk = new Hammer.Manager dragElement,
        dragLockToAxis: true
        dragBlockHorizontal: true
        preventDefault: true

      @mk.add pan
      @mk.on 'panstart'  , _SPL.onStart.bind(@, dragElement)
      @mk.on 'pan'       , _SPL.onMove.bind(@)
      @mk.on 'panend'    , _SPL.onEnd.bind(@, dragElement)
      @mk.on 'pancancel' , _SPL.onEnd.bind(@, dragElement)

      # Keyboard Event
      @eventCall = 'keydown': _SPL.onKeydown.bind(@)
      @widget.addEventListener 'keydown', @eventCall.keydown

      # Init
      _SPL.onToggle.call(@)
      return

  # Class
  class SwitchSlide
    constructor: (container, options) ->

      # Self instance
      if false is (@ instanceof SwitchSlide)
        return new SwitchSlide container, options

      # Container
      if typeof container == 'string'
        @container = document.querySelector container
      else
        @container = container

      # Check if component was initialized
      initialized = SwitchSlide.data @container
      if initialized instanceof SwitchSlide
        return initialized
      else
        id = ++GUID

      @container.srGUID = id
      instances[id] = @

      # Options
      @options =
        labeledby      : null
        required       : false
        template       : _SPL.getTemplate()
        setElements    : _SPL.setElements
        setSizes       : _SPL.setSizes
        getTapElement  : _SPL.getTapElement
        getDragElement : _SPL.getDragElement
        negative       : false
        swap           : false
        initialize     : 'switchSlide--initialized'
        selectors:
          widget : '.widgetSlide'
          opts   : '.widgetSlide__opt'
          optMin : '.widgetSlide__opt--min'
          optMax : '.widgetSlide__opt--max'
          knob   : '.widgetSlide__knob'

      extend @options, options

      # Swap
      @a = if @options.swap then 1 else 0
      @b = @a ^ 1

      # Radios
      @radios = []
      radios = @container.getElementsByTagName 'input'
      for radio, idx in radios when radio.type == 'radio'
        @radios.push radio

      # Exception
      if @radios.length != 2
        throw new SwitchSlideException '✖ No radios'
      else
        # Initialize
        classie.add @container, @options.initialize

        # Width
        @width = 0

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
        @transform =
          translate:
            x: 0

        # Keyboard
        @keyCodes =
          'space' : 32
          'left'  : 37
          'right' : 39

        # Accessibility
        @aria =
          'tabindex'       : 0
          'role'           : 'slider'
          'aria-valuemin'  : @radios[@a].title
          'aria-valuemax'  : @radios[@b].title
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

        # Event change
        @eventChange = new CustomEvent 'change'

        _SPL.build.call(@)

      return

    # Trigger event
    emitToggle: ->
      @.emitEvent 'toggle', @eventToggleParams
      return

    # Swap value
    swap: (v) ->
      @shift = if v? then v else !@shift
      _SPL.onToggle.call(@)
      return

    # Reset value
    reset: ->
      @shift = null
      _SPL.onToggle.call(@)
      return

    # Show or hide element
    isActive: ->
      if @active isnt null
        method = if @active then 'add' else 'remove'
        classie[method] @knob, 'is-active'
      return

    # Update WAI-ARIA - Accessibility
    updateAria: ->
      if @shift isnt null
        v = if @shift is on then @radios[@b].title else @radios[@a].title
        @widget.setAttribute 'aria-valuenow', v
        @widget.setAttribute 'aria-valuetext', v
      return

    # Update current value
    updateValor: ->
      @valor = null
      if @shift isnt null
        @valor = if @shift is on then @radios[@b].value else @radios[@a].value

      if @eventToggleParams?
        @eventToggleParams[0].value = @valor
      return

    # Update element position
    updatePosition: ->
      value = ["translate3d(#{@transform.translate.x}px, 0, 0)"]
      dragElement = @options.getDragElement.call(@)
      dragElement.style[transformProperty] = value.join " "
      return

    # Destroy widget
    destroy: ->
      if @container isnt null

        # Remove Keyboard event
        @widget.removeEventListener 'keydown', @eventCall.keydown

        # Destroy Hammer Events
        @mk.destroy()
        @mc.destroy()

        # Remove @widget
        @widget.removeAttribute attr for attr of @aria
        if @container.contains @widget
          @container.removeChild @widget

        # Remove classes and attributes
        classie.remove @container, @options.initialize
        @container.removeAttribute "style"

        # Remove reference
        delete @container.srGUID

        @container = null
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
    id = el and el.srGUID
    return id and instances[id]

  return SwitchSlide
