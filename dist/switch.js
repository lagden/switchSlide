
/*
switch.js - SwitchSlide

It is a plugin that show `radios buttons` like switch slide

@author      Thiago Lagden <lagden [at] gmail.com>
@copyright   Author
 */
(function(root, factory) {
  if (typeof define === "function" && define.amd) {
    define(['get-style-property/get-style-property', 'classie/classie', 'eventEmitter/EventEmitter', 'hammerjs/hammer'], factory);
  } else {
    root.SwitchSlide = factory(root.getStyleProperty, root.classie, root.EventEmitter, root.Hammer);
  }
})(this, function(getStyleProperty, classie, EventEmitter, Hammer) {
  'use strict';
  var GUID, SwitchSlide, SwitchSlideException, extend, instances, transformProperty, _SPL;
  extend = function(a, b) {
    var prop;
    for (prop in b) {
      a[prop] = b[prop];
    }
    return a;
  };
  transformProperty = getStyleProperty('transform');
  GUID = 0;
  instances = {};
  SwitchSlideException = (function() {
    function SwitchSlideException(message, name) {
      this.message = message;
      this.name = name != null ? name : 'SwitchSlideException';
    }

    return SwitchSlideException;

  })();
  _SPL = {
    getTemplate: function() {
      return '<div class="widgetSlide"> <div class="widgetSlide__opt widgetSlide__opt--min"> <span>{captionMin}</span> </div> <div class="widgetSlide__knob"></div> <div class="widgetSlide__opt widgetSlide__opt--max"> <span>{captionMax}</span> </div>';
    },
    getSizes: function() {
      var clone, knob, sMax, sMin, sizes, widget;
      clone = this.container.cloneNode(true);
      clone.style.visibility = 'hidden';
      clone.style.position = 'absolute';
      document.body.appendChild(clone);
      widget = clone.querySelector(this.options.selectors.widget);
      sMin = widget.querySelector(this.options.selectors.optMin);
      sMax = widget.querySelector(this.options.selectors.optMax);
      knob = widget.querySelector(this.options.selectors.knob);
      sizes = {
        'sMin': sMin.clientWidth,
        'sMax': sMax.clientWidth,
        'knob': knob.clientWidth
      };
      document.body.removeChild(clone);
      clone = null;
      return sizes;
    },
    onToggle: function() {
      var a, b, radio, width, _i, _j, _len, _len1, _ref, _ref1;
      width = this.options.negative ? this.width * -1 : this.width;
      if (this.ligado !== null) {
        this.active = true;
        this.transform.translate.x = this.ligado ? width : 0;
        a = this.ligado ? 1 : 0;
        b = a ^ 1;
        _SPL.checked(this.radios[a]);
        _SPL.unchecked(this.radios[b]);
      } else {
        this.active = false;
        this.transform.translate.x = width / 2;
        _ref = this.radios;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          radio = _ref[_i];
          _SPL.unchecked(radio);
        }
      }
      this.isActive();
      this.updateAria();
      this.updateValor();
      this.updatePosition();
      this.emitToggle();
      _ref1 = this.radios;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        radio = _ref1[_j];
        if (radio.checked) {
          radio.dispatchEvent(this.eventChange);
        }
      }
    },
    onStart: function(el, event) {
      el.focus();
      classie.add(el, 'is-dragging');
    },
    onMove: function(event) {
      var v, width;
      width = this.options.negative ? this.width * -1 : this.width;
      v = (width / 2) + event.deltaX;
      if (this.ligado !== null) {
        v = this.ligado ? width + event.deltaX : event.deltaX;
      }
      if (this.options.negative) {
        this.transform.translate.x = Math.min(0, Math.max(width, v));
      } else {
        this.transform.translate.x = Math.min(width, Math.max(v, 0));
      }
      this.updatePosition();
    },
    onEnd: function(el, event) {
      this.ligado = Math.abs(this.transform.translate.x) > (this.width / 2);
      classie.remove(el, 'is-dragging');
      _SPL.onToggle.call(this);
    },
    onTap: function(el, event) {
      var center, rect;
      rect = el.getBoundingClientRect();
      center = rect.left + (rect.width / 2);
      if (this.options.negative) {
        this.ligado = event.center.x < center;
      } else {
        this.ligado = event.center.x > center;
      }
      _SPL.onToggle.call(this);
    },
    onKeydown: function(event) {
      var dispara;
      dispara = false;
      switch (event.keyCode) {
        case this.keyCodes.space:
          this.ligado = !this.ligado;
          dispara = true;
          break;
        case this.keyCodes.right:
          this.ligado = !this.options.negative;
          dispara = true;
          break;
        case this.keyCodes.left:
          this.ligado = this.options.negative;
          dispara = true;
      }
      if (dispara) {
        _SPL.onToggle.call(this);
      }
    },
    setElements: function() {
      this.widget = this.container.querySelector(this.options.selectors.widget);
      this.sMin = this.widget.querySelector(this.options.selectors.optMax);
      this.sMax = this.widget.querySelector(this.options.selectors.optMin);
      return this.knob = this.widget.querySelector(this.options.selectors.knob);
    },
    setSizes: function() {
      this.sMin.style.width = "" + this.width + "px";
      this.sMax.style.width = "" + this.width + "px";
      this.knob.style.width = "" + this.width + "px";
      return this.container.style.width = (this.width * 2) + 'px';
    },
    getTapElement: function() {
      return this.widget;
    },
    getDragElement: function() {
      return this.knob;
    },
    checked: function(radio) {
      radio.setAttribute('checked', '');
      radio.checked = true;
    },
    unchecked: function(radio) {
      radio.removeAttribute('checked');
      radio.checked = false;
    },
    aria: function(el) {
      var attrib, value, _ref, _results;
      _ref = this.aria;
      _results = [];
      for (attrib in _ref) {
        value = _ref[attrib];
        _results.push(el.setAttribute(attrib, value));
      }
      return _results;
    },
    build: function() {
      var captionMax, captionMin, content, dragElement, labels, pan, r, tap, tapElement;
      captionMin = captionMax = '';
      labels = this.container.getElementsByTagName('label');
      if (labels.length === 2) {
        captionMin = labels[this.a].textContent;
        captionMax = labels[this.b].textContent;
      } else {
        console.warn('✖ No labels');
      }
      r = {
        'captionMin': captionMin,
        'captionMax': captionMax
      };
      content = this.options.template.replace(/\{(.*?)\}/g, function(a, b) {
        return r[b];
      });
      this.container.insertAdjacentHTML('afterbegin', content);
      this.options.setElements.call(this);
      this.sizes = _SPL.getSizes.call(this);
      this.sizes.max = Math.max(this.sizes.sMax, this.sizes.sMin);
      this.width = this.sizes.max;
      this.options.setSizes.call(this);
      _SPL.aria.call(this, this.widget);
      tapElement = this.options.getTapElement.call(this);
      tap = new Hammer.Tap;
      this.mc = new Hammer.Manager(tapElement, {
        dragLockToAxis: true,
        dragBlockHorizontal: true,
        preventDefault: true
      });
      this.mc.add(tap);
      this.mc.on('tap', _SPL.onTap.bind(this, tapElement));
      dragElement = this.options.getDragElement.call(this);
      pan = new Hammer.Pan({
        direction: Hammer.DIRECTION_HORIZONTAL
      });
      this.mk = new Hammer.Manager(dragElement, {
        dragLockToAxis: true,
        dragBlockHorizontal: true,
        preventDefault: true
      });
      this.mk.add(pan);
      this.mk.on('panstart', _SPL.onStart.bind(this, dragElement));
      this.mk.on('pan', _SPL.onMove.bind(this));
      this.mk.on('panend', _SPL.onEnd.bind(this, dragElement));
      this.mk.on('pancancel', _SPL.onEnd.bind(this, dragElement));
      this.eventCall = {
        'keydown': _SPL.onKeydown.bind(this)
      };
      this.widget.addEventListener('keydown', this.eventCall.keydown);
      _SPL.onToggle.call(this);
    }
  };
  SwitchSlide = (function() {
    function SwitchSlide(container, options) {
      var id, idx, initialized, radio, radios, _i, _len;
      if (false === (this instanceof SwitchSlide)) {
        return new SwitchSlide(container, options);
      }
      if (typeof container === 'string') {
        this.container = document.querySelector(container);
      } else {
        this.container = container;
      }
      initialized = SwitchSlide.data(this.container);
      if (initialized instanceof SwitchSlide) {
        return initialized;
      } else {
        id = ++GUID;
      }
      this.container.srGUID = id;
      instances[id] = this;
      this.options = {
        labeledby: null,
        required: false,
        template: _SPL.getTemplate(),
        setElements: _SPL.setElements,
        setSizes: _SPL.setSizes,
        getTapElement: _SPL.getTapElement,
        getDragElement: _SPL.getDragElement,
        negative: false,
        swap: false,
        initialize: 'switchSlide--initialized',
        selectors: {
          widget: '.widgetSlide',
          opts: '.widgetSlide__opt',
          optMin: '.widgetSlide__opt--min',
          optMax: '.widgetSlide__opt--max',
          knob: '.widgetSlide__knob'
        }
      };
      extend(this.options, options);
      this.a = this.options.swap ? 1 : 0;
      this.b = this.a ^ 1;
      this.radios = [];
      radios = this.container.getElementsByTagName('input');
      for (idx = _i = 0, _len = radios.length; _i < _len; idx = ++_i) {
        radio = radios[idx];
        if (radio.type === 'radio') {
          this.radios.push(radio);
        }
      }
      if (this.radios.length !== 2) {
        throw new SwitchSlideException('✖ No radios');
      } else {
        classie.add(this.container, this.options.initialize);
        this.width = 0;
        this.ligado = null;
        if (this.radios[this.a].checked) {
          this.ligado = false;
        }
        if (this.radios[this.b].checked) {
          this.ligado = true;
        }
        this.valor = null;
        this.updateValor();
        this.active = false;
        this.transform = {
          translate: {
            x: 0
          }
        };
        this.keyCodes = {
          'space': 32,
          'left': 37,
          'right': 39
        };
        this.aria = {
          'tabindex': 0,
          'role': 'slider',
          'aria-valuemin': this.radios[this.a].title,
          'aria-valuemax': this.radios[this.b].title,
          'aria-valuetext': null,
          'aria-valuenow': null,
          'aria-labeledby': this.options.labeledby,
          'aria-required': this.options.required
        };
        this.eventToggleParam = [
          {
            'instance': this,
            'radios': this.radios,
            'value': this.valor
          }
        ];
        this.eventChange = new CustomEvent('change');
        _SPL.build.call(this);
      }
      return;
    }

    SwitchSlide.prototype.emitToggle = function() {
      this.emitEvent('toggle', this.eventToggleParam);
    };

    SwitchSlide.prototype.swap = function(v) {
      this.ligado = v != null ? v : !this.ligado;
      _SPL.onToggle.call(this);
    };

    SwitchSlide.prototype.reset = function() {
      this.ligado = null;
      _SPL.onToggle.call(this);
    };

    SwitchSlide.prototype.isActive = function() {
      var method;
      method = this.active ? 'add' : 'remove';
      classie[method](this.knob, 'is-active');
    };

    SwitchSlide.prototype.updateAria = function() {
      var v;
      if (this.ligado !== null) {
        v = this.ligado === true ? this.radios[this.b].title : this.radios[this.a].title;
        this.widget.setAttribute('aria-valuenow', v);
        this.widget.setAttribute('aria-valuetext', v);
      }
    };

    SwitchSlide.prototype.updateValor = function() {
      this.valor = null;
      if (this.ligado !== null) {
        this.valor = this.ligado === true ? this.radios[this.b].value : this.radios[this.a].value;
      }
      if (this.eventToggleParam != null) {
        this.eventToggleParam[0].value = this.valor;
      }
    };

    SwitchSlide.prototype.updatePosition = function() {
      var dragElement, value;
      value = ["translate3d(" + this.transform.translate.x + "px, 0, 0)"];
      dragElement = this.options.getDragElement.call(this);
      dragElement.style[transformProperty] = value.join(" ");
    };

    SwitchSlide.prototype.destroy = function() {
      var attr;
      if (this.container !== null) {
        this.widget.removeEventListener('keydown', this.eventCall.keydown);
        this.mk.destroy();
        this.mc.destroy();
        for (attr in this.aria) {
          this.widget.removeAttribute(attr);
        }
        if (this.container.contains(this.widget)) {
          this.container.removeChild(this.widget);
        }
        classie.remove(this.container, this.options.initialize);
        this.container.removeAttribute("style");
        delete this.container.srGUID;
        this.container = null;
      }
    };

    return SwitchSlide;

  })();
  extend(SwitchSlide.prototype, EventEmitter.prototype);
  SwitchSlide.data = function(el) {
    var id;
    id = el && el.srGUID;
    return id && instances[id];
  };
  return SwitchSlide;
});
