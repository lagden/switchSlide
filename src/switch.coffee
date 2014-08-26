###
switch.js - SwitchSlide

It is a plugin that show `radios buttons` like slide switch

@author      Thiago Lagden <lagden [at] gmail.com>
@copyright   Author
###

((root, factory) ->
  if typeof define is "function" and define.amd
    define [
        'get-style-property/get-style-property'
        'classie/classie'
        'eventEmitter/EventEmitter'
        'greensock/TweenMax'
        'greensock/utils/Draggable'
        'greensock/plugins/CSSPlugin'
      ], factory
  else
    root.SwitchSlide = factory root.getStyleProperty,
                               root.classie,
                               root.EventEmitter,
                               root.TweenMax,
                               root.Draggable,
                               root.CSSPlugin
  return
) @, (getStyleProperty, classie, EventEmitter, TM, Draggable, CSSPlugin) ->

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
        '<div class="switchSlide__opt switchSlide__opt--on">{captionOn}</div>'
        '<div class="switchSlide__opt switchSlide__opt--off">{captionOff}</div>'
        '<div class="switchSlide__knob"></div>'
      ].join ''

    endDrag: (event) ->
      console.log event
      return

    build: () ->
      captionOn = captionOff = ''

      labels = @container.getElementsByTagName 'label'
      if labels.length == 2
        captionOn  = labels[0].textContent
        captionOff = labels[1].textContent
      else
        console.warn '✖ No labels'

      # Template Render
      r =
        'captionOn'  : captionOn
        'captionOff' : captionOff
        'valuemax'    : @aria['aria-valuemax']
        'valuemin'   : @aria['aria-valuemin']
        'valuenow'   : @aria['aria-valuenow']
        'labeledby'  : @aria['aria-labeledby']
        'required'   : @aria['aria-required']

      content = @template.replace /\{(.*?)\}/g, (a, b) ->
        return r[b]

      @container.insertAdjacentHTML 'afterbegin', content

      # Size elements
      @sOn   = @container.querySelector '.switchSlide__opt--on'
      @sOff  = @container.querySelector '.switchSlide__opt--off'
      @knob  = @container.querySelector '.switchSlide__knob'

      sizes = @getSizes()

      @size = Math.max sizes.sOn, sizes.sOff

      @sOn.style.width = "#{@size}px"
      @sOff.style.width = "#{@size}px"
      @knob.style.width = "#{@size}px"
      @knob.style.height = "#{sizes.cHeight}px"
      @container.style.width = (@size * 2)  + 'px'

      containerWidth = (@size * 2)

      TM.to @knob, 0.5,
        x: Math.round(100 / containerWidth) * containerWidth
        delay: 0.1

      @draggable = Draggable.create @knob,
        bounds: @container
        edgeResistance: 0.65
        force3D: true
        type: 'x'
        endDrag: _SPL.endDrag.bind(@)


      # # Keyboard
      # @sFlex.addEventListener 'keydown', _SPL.onKeydown.bind(@), false

      # # Event toggle param
      # @eventToggleParam = [
      #   'instance' : @
      #   'container': @container
      #   'radios'   : @radios
      #   'handler'  : @sFlex
      #   'value'    : @valor
      # ]

      # Event change
      @eventChange = new CustomEvent 'change'

      # Init
      # _SPL.onToggle.bind(@)()
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
        return null
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
        console.err '✖ No radios'
        return null

      @template = _SPL.getTemplate()
      @size = 0

      @side = null
      @side = false if @radios[0].checked and !@radios[1].checked
      @side = true  if @radios[1].checked and !@radios[0].checked

      # @valor = @valorUpdate()

      @active = false

      # Animation
      # @ticking = false
      # @transform =
      #   translate:
      #     x: 0

      @aria =
        'aria-valuemax'  : @radios[0].title
        'aria-valuemin'  : @radios[1].title
        'aria-valuetext' : null
        'aria-valuenow'  : null
        'aria-labeledby' : labeledby
        'aria-required'  : required

      @keyCodes =
        'space' : 32
        'left'  : 37
        'right' : 39

      _SPL.build.bind(@)()

    toggle: (v) ->

      @side = if v isnt undefined then v else @side

      if @side isnt null
        @active = true
        @transform.translate.x = if @side then -@size else 0

        if @side
          @radios[0].removeAttribute 'checked'
          @radios[0].checked = false
          @radios[1].setAttribute 'checked', ''
          @radios[1].checked = true
        else
          @radios[1].removeAttribute 'checked'
          @radios[1].checked = false
          @radios[0].setAttribute 'checked', ''
          @radios[0].checked = true

      else
        @active = false
        @transform.translate.x = -@size / 2
        for radio in @radios
          radio.removeAttribute 'checked'
          radio.checked = false

      @ariaAttr()
      @captionsActive()
      @requestUpdate()
      return

    swap: (v) ->
      v = if v isnt undefined then v else null
      @side = if v isnt null then !v else !@side
      _SPL.onToggle.bind(@)()
      return

    reset: ->
      @side = null
      _SPL.onToggle.bind(@)()
      return

    getSizes: ->
      clone = @container.cloneNode true
      clone.style.visibility = 'hidden'
      clone.style.position   = 'absolute'

      # Magic
      document.body.appendChild clone

      sOnSelector  = '.switchSlide__opt--on'
      sOffSelector = '.switchSlide__opt--off'

      sOn  = clone.querySelector sOnSelector
      sOff = clone.querySelector sOffSelector

      sizes =
        'sOn': sOn.clientWidth
        'sOff': sOff.clientWidth
        'cHeight': clone.clientHeight

      document.body.removeChild clone
      clone = null
      return sizes

    ariaAttr: ->
      if @side == null
        v = @side
      else
        v = if @side then @radios[1].title else @radios[0].title
      @sFlex.setAttribute 'aria-valuenow', v
      @sFlex.setAttribute 'aria-valuetext', v
      return

    valorUpdate: ->
      if @side == null
        v = @side
      else
        v = if @side then @radios[1].value else @radios[0].value
      return v

    captionsActive: ->
      method = if @active then 'add' else 'remove'
      classie[method] @sOn, 'is-active'
      classie[method] @sOff, 'is-active'
      return

    updateTransform: ->
      value = ["translate3d(#{@transform.translate.x}px, 0, 0)"]
      @sFlex.style[transformProperty] = value.join " "
      @ticking = false
      return

    requestUpdate: ->
      if @ticking == false
        @ticking = true
        requestAnimationFrame @updateTransform.bind(@)
      return

    destroy: ->
      style = @container.style
      style.width = ''
      @container.removeChild @sFlex
      @container.removeAttribute "data-sr#{@container.srGUID}"
      delete @container.srGUID
      @sFlex = null
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
