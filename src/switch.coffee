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

  # globally unique identifiers
  GUID = 0

  # internal store of all SwitchSlide intances
  instances = {}

  # Exception
  class SwitchSlideException
    constructor: (@message, @name='SwitchSlideException') ->

  _SPL =
    # Template
    getTemplate: ->
      return '<div class="widgetSlide">
        <div class="widgetSlide__opt widgetSlide__opt--off">
        <span>{captionOff}</span>
        </div>
        <div class="widgetSlide__opt widgetSlide__opt--on">
        <span>{captionOn}</span>
        </div>
        <div class="widgetSlide__knob"></div>'

    getSizes: ->
      clone = @container.cloneNode true
      clone.style.visibility = 'hidden'
      clone.style.position   = 'absolute'

      document.body.appendChild clone

      widget = clone.querySelector @options.selectors.widget
      sOff   = widget.querySelector @options.selectors.optOff
      sOn    = widget.querySelector @options.selectors.optOn
      knob   = widget.querySelector @options.selectors.knob

      sizes =
        'sOff': sOff.clientWidth
        'sOn' : sOn.clientWidth
        'knob': knob.clientWidth

      document.body.removeChild clone
      clone = null
      return sizes

    # Event Handlers
    onToggle: ->
      if @ligado isnt null
        width = if @options.negative then (@width * -1) else @width
        @active = true
        @transform.translate.x = if @ligado then width else 0

        a = if @ligado then 1 else 0
        b = a^1

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
      width = if @options.negative then (@width * -1) else @width
      v = (width / 2) + event.deltaX

      if @ligado isnt null
        v = if @ligado then width + event.deltaX else event.deltaX

      if @options.negative
        @transform.translate.x = Math.min 0, Math.max width, v
      else
        @transform.translate.x = Math.min width, Math.max v, 0

      @updatePosition()
      return

    onEnd: (el, event) ->
      @ligado = Math.abs(@transform.translate.x) > (@width / 2)
      classie.remove el, 'is-dragging'
      _SPL.onToggle.call(@)
      return

    onTap: (el, event) ->
      rect = el.getBoundingClientRect()
      center = rect.left + (rect.width / 2)
      if @options.negative
        @ligado = event.center.x < center
      else
        @ligado = event.center.x > center

      _SPL.onToggle.call(@)
      return

    onKeydown: (event) ->
      dispara = false
      switch event.keyCode
        when @keyCodes.space
          @ligado = !@ligado
          dispara = true

        when @keyCodes.right
          @ligado = !@options.negative
          dispara = true

        when @keyCodes.left
          @ligado = @options.negative
          dispara = true

      _SPL.onToggle.call(@) if dispara
      return

    setElements: ->
      @widget = @container.querySelector @options.selectors.widget
      @sOff   = @widget.querySelector @options.selectors.optOn
      @sOn    = @widget.querySelector @options.selectors.optOff
      @knob   = @widget.querySelector @options.selectors.knob

    setSizes: ->
      @sOff.style.width = "#{@width}px"
      @sOn.style.width  = "#{@width}px"
      @knob.style.width = "#{@width}px"
      @container.style.width = (@width * 2)  + 'px'

    getTapElement: ->
      return @widget

    getDragElement: ->
      return @knob

    checked: (radio) ->
      radio.setAttribute 'checked', ''
      radio.checked = true
      return

    unchecked: (radio) ->
      radio.removeAttribute 'checked'
      radio.checked = false
      return

    aria: (el) ->
      el.setAttribute attrib, value for attrib, value of @aria

    build: ->
      captionOff = captionOn = ''

      labels = @container.getElementsByTagName 'label'
      if labels.length == 2
        captionOff  = labels[0].textContent
        captionOn   = labels[1].textContent
      else
        console.warn '✖ No labels'

      # Template Render
      r =
        'captionOff' : captionOff
        'captionOn'  : captionOn

      content = @options.template.replace /\{(.*?)\}/g, (a, b) ->
        return r[b]

      @container.insertAdjacentHTML 'afterbegin', content

      # Elements and size
      @options.setElements.call(@)

      # Set widths
      @sizes = _SPL.getSizes.call(@)
      @sizes.max = Math.max @sizes.sOn, @sizes.sOff
      @width = @sizes.max
      @options.setSizes.call(@)

      # Aria
      _SPL.aria.call(@, @widget)

      # Drag and Tap
      tapElement = @options.getTapElement.call(@)
      tap = new Hammer.Tap
      @mc = new Hammer.Manager tapElement,
        dragLockToAxis: true
        dragBlockHorizontal: true
        preventDefault: true

      @mc.add tap
      @mc.on 'tap', _SPL.onTap.bind(@, tapElement)

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

      # Keyboard
      @eventCall =
        'keydown': _SPL.onKeydown.bind(@)

      @widget.addEventListener 'keydown', @eventCall.keydown

      # Init
      _SPL.onToggle.call(@)
      return

  # Master
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
        initialize     : 'switchSlide--initialized'
        selectors:
          widget : '.widgetSlide'
          opts   : '.widgetSlide__opt'
          optOff : '.widgetSlide__opt--off'
          optOn  : '.widgetSlide__opt--on'
          knob   : '.widgetSlide__knob'

      extend @options, options

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

        # Largura
        @width = 0

        # Ligado, desligado ou nulo
        @ligado = null
        @ligado = false if @radios[0].checked and !@radios[1].checked
        @ligado = true  if @radios[1].checked and !@radios[0].checked

        # Valor Inicial
        @valor = null
        @updateValor()

        # Knob ativado
        @active = false

        # Animation
        @transform =
          translate:
            x: 0

        # Keyboard
        @keyCodes =
          'space' : 32
          'left'  : 37
          'right' : 39

        # Acessibilidade
        @aria =
          'tabindex'       : 0
          'role'           : 'slider'
          'aria-valuemin'  : @radios[0].title
          'aria-valuemax'  : @radios[1].title
          'aria-valuetext' : null
          'aria-valuenow'  : null
          'aria-labeledby' : @options.labeledby
          'aria-required'  : @options.required

        # Event toggle param
        @eventToggleParam = [
          'instance' : @
          'radios'   : @radios
          'value'    : @valor
        ]

        # Event change
        @eventChange = new CustomEvent 'change'

        _SPL.build.call(@)

      return

    emitToggle: ->
      @.emitEvent 'toggle', @eventToggleParam
      return

    swap: (v) ->
      @ligado = if v? then v else !@ligado
      _SPL.onToggle.call(@)
      return

    reset: ->
      @ligado = null
      _SPL.onToggle.call(@)
      return

    isActive: ->
      method = if @active then 'add' else 'remove'
      classie[method] @knob, 'is-active'
      return

    updateAria: ->
      if @ligado isnt null
        v = if @ligado is on then @radios[1].title else @radios[0].title
        @widget.setAttribute 'aria-valuenow', v
        @widget.setAttribute 'aria-valuetext', v
      return

    updateValor: ->
      @valor = null
      if @ligado isnt null
        @valor = if @ligado is on then @radios[1].value else @radios[0].value

      if @eventToggleParam?
        @eventToggleParam[0].value = @valor
      return

    updatePosition: ->
      value = ["translate3d(#{@transform.translate.x}px, 0, 0)"]
      dragElement = @options.getDragElement.call(@)
      dragElement.style[transformProperty] = value.join " "
      return

    destroy: ->
      if @container isnt null

        # Remove Event from @container
        @widget.removeEventListener 'keydown', @eventCall.keydown

        # Destroy Hammer Events
        @mk.destroy()
        @mc.destroy()


        # Remove @elements
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
