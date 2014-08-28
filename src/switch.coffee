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

  # Transform property cross-browser
  transformProperty = getStyleProperty 'transform'

  # globally unique identifiers
  GUID = 0

  # internal store of all SwitchSlide intances
  instances = {}

  _SPL =
    # Template
    getTemplate: ->
      [
        '<div class="switchSlide__opt switchSlide__opt--off">'
        '<span>{captionOff}</span></div>'
        '<div class="switchSlide__opt switchSlide__opt--on">'
        '<span>{captionOn}</span></div>'
        '<div class="switchSlide__knob"></div>'
      ].join ''

    getSizes: ->
      clone = @container.cloneNode true
      clone.style.visibility = 'hidden'
      clone.style.position   = 'absolute'

      document.body.appendChild clone

      sOnSelector  = '.switchSlide__opt--on'
      sOffSelector = '.switchSlide__opt--off'

      sOn  = clone.querySelector sOnSelector
      sOff = clone.querySelector sOffSelector

      sizes =
        'sOn': sOn.clientWidth
        'sOff': sOff.clientWidth

      document.body.removeChild clone
      clone = null
      return sizes

    # Event Handlers
    onToggle: ->
      if @ligado isnt null
        @active = true
        @transform.translate.x = if @ligado then @size else 0

        a = if @ligado then 1 else 0
        b = a^1

        _SPL.checked(@radios[a])
        _SPL.unchecked(@radios[b])

      else
        @active = false
        @transform.translate.x = @size / 2
        _SPL.unchecked(radio) for radio in @radios

      @isActive()
      @updateAria()
      @updateValor()
      @updatePosition()

      @.emitEvent 'toggle', @eventToggleParam
      for radio in @radios when radio.checked
        radio.dispatchEvent @eventChange
      return

    onStart: (el, event) ->
      el.focus()
      classie.add el, 'is-dragging'
      return

    onMove: (event) ->
      v = (@size / 2) + event.deltaX

      if @ligado isnt null
        v = if @ligado then @size + event.deltaX else event.deltaX

      @transform.translate.x = Math.min @size, Math.max v, 0
      @updatePosition()
      return

    onEnd: (el, event) ->
      @ligado = Math.abs(@transform.translate.x) > (@size / 2)
      classie.remove el, 'is-dragging'
      _SPL.onToggle.call(@)
      return

    onTap: (el, event) ->
      rect = el.getBoundingClientRect()
      center = rect.left + (rect.width / 2)
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
          @ligado = true
          dispara = true

        when @keyCodes.left
          @ligado = false
          dispara = true

      _SPL.onToggle.call(@) if dispara
      return

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

    build: () ->
      captionOn = captionOff = ''

      labels = @container.getElementsByTagName 'label'
      if labels.length == 2
        captionOff  = labels[0].textContent
        captionOn   = labels[1].textContent
      else
        console.warn '✖ No labels'

      # Template Render
      r =
        'captionOn'  : captionOn
        'captionOff' : captionOff

      content = @template.replace /\{(.*?)\}/g, (a, b) ->
        return r[b]

      @container.insertAdjacentHTML 'afterbegin', content

      # Elements and Size elements
      @elements = []

      sizes = _SPL.getSizes.call(@)
      @size = Math.max sizes.sOn, sizes.sOff

      @sOn   = @container.querySelector '.switchSlide__opt--on'
      @sOff  = @container.querySelector '.switchSlide__opt--off'
      @drag  = @container.querySelector '.switchSlide__knob'

      @elements.push @sOn
      @elements.push @sOff
      @elements.push @drag

      # Width
      el.style.width = "#{@size}px" for el in @elements
      @container.style.width = (@size * 2)  + 'px'

      # Aria
      _SPL.aria.call(@, @container)

      # Drag and Tap
      #
      # Container
      tap = new Hammer.Tap
      @mc = new Hammer.Manager @container,
        dragLockToAxis: true
        dragBlockHorizontal: true
        preventDefault: true

      @mc.add tap
      @mc.on 'tap', _SPL.onTap.bind(@, @container)

      # Knob
      pan = new Hammer.Pan direction: Hammer.DIRECTION_HORIZONTAL
      @mk = new Hammer.Manager @drag,
        dragLockToAxis: true
        dragBlockHorizontal: true
        preventDefault: true

      @mk.add pan
      @mk.on 'panstart'  , _SPL.onStart.bind(@, @drag)
      @mk.on 'pan'       , _SPL.onMove.bind(@)
      @mk.on 'panend'    , _SPL.onEnd.bind(@, @drag)
      @mk.on 'pancancel' , _SPL.onEnd.bind(@, @drag)

      # Keyboard
      @eventCall =
        'keydown': _SPL.onKeydown.bind(@)

      @container.addEventListener 'keydown', @eventCall.keydown

      # Init
      _SPL.onToggle.call(@)
      return

    initCheck: (container) ->
      regex = /data-sr(\d+)/i
      attribs = container.attributes
      data = attrib.name for attrib in attribs when regex.test attrib.name
      return true if !!data

  # Master
  class SwitchSlide extends EventEmitter
    constructor: (container, required, labeledby) ->

      # Self instance
      if false is (@ instanceof SwitchSlide)
        return new SwitchSlide(container, required, labeledby)

      labeledby = labeledby || null
      required = required || false

      # Check if component was initialized
      if _SPL.initCheck container
        console.warn 'The component has been initialized.'
        return
      else
        id = ++GUID

        # Container
        @container = container
        @container.srGUID = id
        instances[id] = @
        container.setAttribute "data-sr#{id}", ''

      # Radios
      @radios = []
      radios = @container.getElementsByTagName 'input'
      for radio, idx in radios when radio.type == 'radio'
        radio.setAttribute 'data-side', idx
        @radios.push radio

      if @radios.length != 2
        console.error '✖ No radios'
        return

      # Template
      @template = _SPL.getTemplate()

      # Largura
      @size = 0

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
        'aria-labeledby' : labeledby
        'aria-required'  : required

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
      classie[method] @drag, 'is-active'
      return

    updateAria: ->
      if @ligado isnt null
        v = if @ligado is on then @radios[1].title else @radios[0].title
        @container.setAttribute 'aria-valuenow', v
        @container.setAttribute 'aria-valuetext', v
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
      @drag.style[transformProperty] = value.join " "
      return

    destroy: ->
      if @container isnt null
        # Remove attributes from radios
        radio.removeAttribute 'data-side' for radio in @radios

        # Remove Event from @container
        @container.removeEventListener 'keydown', @eventCall.keydown

        # Destroy Hammer Events
        @mk.destroy()
        @mc.destroy()

        # Remove @elements from @container
        @container.removeChild el for el in @elements

        # Remove attributes from @container
        @container.removeAttribute attr for attr of @aria
        @container.removeAttribute "class"
        @container.removeAttribute "style"
        @container.removeAttribute "data-sr#{@container.srGUID}"

        # Remove reference
        delete @container.srGUID

        @container = null
      return

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
