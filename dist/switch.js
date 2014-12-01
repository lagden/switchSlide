
/*
switch.js - SwitchSlide

It is a plugin that show `radios buttons` like switch slide

@author      Thiago Lagden <lagden [at] gmail.com>
@copyright   Author
 */
(function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    define(['get-style-property/get-style-property', 'classie/classie', 'eventEmitter/EventEmitter', 'hammerjs/hammer'], function(getStyleProperty, classie, EventEmitter, Hammer) {
      return factory(getStyleProperty, classie, EventEmitter, Hammer);
    });
  } else {
    root.SwitchSlide = factory(root.getStyleProperty, root.classie, root.EventEmitter, root.Hammer);
  }
})(this, function(getStyleProperty, classie, EventEmitter, Hammer) {
  'use strict';
  var GUID, SwitchSlide, SwitchSlideException, docBody, extend, instances, isElement, removeAllChildren, transformProperty;
  docBody = document.querySelector('body');
  extend = function(a, b) {
    var prop;
    for (prop in b) {
      a[prop] = b[prop];
    }
    return a;
  };
  isElement = function(obj) {
    if (typeof HTMLElement === 'object') {
      return obj instanceof HTMLElement;
    } else {
      return obj && typeof obj === 'object' && obj.nodeType === 1 && typeof obj.nodeName === 'string';
    }
  };
  removeAllChildren = function(el) {
    var c;
    while (el.hasChildNodes()) {
      c = el.lastChild;
      if (c.hasChildNodes()) {
        el.removeChild(removeAllChildren(c));
      } else {
        el.removeChild(c);
      }
    }
    return el;
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
  SwitchSlide = (function() {
    var _SPL;

    _SPL = {
      getTemplate: function() {
        return '<div class="widgetSlide"> <div class="widgetSlide__opt widgetSlide__opt--min"> <span>{captionMin}</span> </div> <div class="widgetSlide__knob"></div> <div class="widgetSlide__opt widgetSlide__opt--max"> <span>{captionMax}</span> </div> </div>';
      },
      getSizes: function(container, options) {
        var clone, knob, knobComputedStyle, knobMarLeft, knobMarRight, sMax, sMin, sizes, widget;
        clone = container.cloneNode(true);
        clone.style.visibility = 'hidden';
        clone.style.position = 'absolute';
        docBody.appendChild(clone);
        widget = clone.querySelector(options.widget);
        sMin = widget.querySelector(options.optMin);
        sMax = widget.querySelector(options.optMax);
        knob = widget.querySelector(options.knob);
        knobComputedStyle = window.getComputedStyle(knob);
        knobMarLeft = parseInt(knobComputedStyle.marginLeft, 10);
        knobMarRight = parseInt(knobComputedStyle.marginRight, 10);
        sizes = {
          'sMin': sMin.clientWidth,
          'sMax': sMax.clientWidth,
          'knob': knob.clientWidth,
          'margin': knobMarLeft + knobMarRight,
          'max': Math.max(sMin.clientWidth, sMax.clientWidth)
        };
        docBody.removeChild(removeAllChildren(clone));
        clone = null;
        widget = null;
        sMin = null;
        sMax = null;
        knob = null;
        return sizes;
      },
      onToggle: function() {
        var a, b, radio, width, _i, _j, _len, _len1, _ref, _ref1;
        width = this.options.negative ? -this.width : this.width;
        if (this.shift !== null) {
          this.active = true;
          this.transform.translate.x = this.shift ? width : 0;
          a = this.shift ? this.b : this.a;
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
        _SPL.isActive.call(this);
        this.updateAria();
        this.updateValor();
        this.updatePosition();
        this.emitToggle();
        _ref1 = this.radios;
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          radio = _ref1[_j];
          if (!radio.checked) {
            continue;
          }
          radio.dispatchEvent(this.eventChange);
          radio.dispatchEvent(this.eventClick);
        }
        width = a = b = null;
      },
      onStart: function(event) {
        this.dragElement.focus();
        classie.add(this.dragElement, 'is-dragging');
      },
      onMove: function(event) {
        var v, width;
        width = this.options.negative ? -this.width : this.width;
        v = (width / 2) + event.deltaX;
        if (this.shift !== null) {
          v = this.shift ? width + event.deltaX : event.deltaX;
        }
        if (this.options.negative) {
          this.transform.translate.x = Math.min(0, Math.max(width, v));
        } else {
          this.transform.translate.x = Math.min(width, Math.max(v, 0));
        }
        this.updatePosition();
        width = v = null;
      },
      onEnd: function(event) {
        this.shift = Math.abs(this.transform.translate.x) > (this.width / 2);
        classie.remove(this.dragElement, 'is-dragging');
        _SPL.onToggle.call(this);
      },
      onTap: function(event) {
        var a, b, data, rect;
        rect = this.tapElement.getBoundingClientRect();
        data = [rect.left + (rect.width / 2), event.center.x];
        a = this.options.negative ? 1 : 0;
        b = a ^ 1;
        this.shift = data[a] < data[b];
        _SPL.onToggle.call(this);
        rect = data = a = b = null;
      },
      onKeydown: function(event) {
        var trigger;
        trigger = true;
        switch (event.keyCode) {
          case this.keyCodes.space:
            this.shift = !this.shift;
            break;
          case this.keyCodes.right:
            this.shift = !this.options.negative;
            break;
          case this.keyCodes.left:
            this.shift = this.options.negative;
            break;
          default:
            trigger = false;
        }
        if (trigger) {
          _SPL.onToggle.call(this);
        }
        trigger = null;
      },
      isActive: function() {
        var method;
        if (this.active !== null) {
          method = this.active ? 'add' : 'remove';
          classie[method](this.knob, 'is-active');
          classie[method](this.widget, 'is-active');
          if (this.active) {
            classie.remove(this.widget, this.options.errorClass);
          }
        }
      },
      getElements: function() {
        this.widget = this.container.querySelector(this.options.widget);
        this.sMin = this.widget.querySelector(this.options.optMax);
        this.sMax = this.widget.querySelector(this.options.optMin);
        this.knob = this.widget.querySelector(this.options.knob);
      },
      setSizes: function() {
        this.sMin.style.width = "" + this.width + "px";
        this.sMax.style.width = "" + this.width + "px";
        this.knob.style.width = "" + (this.width - this.margin) + "px";
        this.container.style.width = (this.width * 2) + 'px';
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
      observer: function(radio) {
        var has, method;
        has = classie.has(radio, this.options.errorClass);
        method = has ? 'add' : 'remove';
        classie[method](this.widget, this.options.errorClass);
      },
      build: function() {
        var attrib, captionMax, captionMin, configObserver, content, hasMutation, labels, m, o, observer, r, radio, that, value, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2, _ref3;
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
        content = this.options.template().replace(/\{(.*?)\}/g, function(a, b) {
          return r[b];
        });
        this.container.insertAdjacentHTML('afterbegin', content);
        labels = captionMin = captionMax = content = null;
        this.options.getElements.call(this);
        this.sizes = _SPL.getSizes(this.container, this.options);
        this.width = this.sizes.max;
        this.margin = this.sizes.margin;
        this.options.setSizes.call(this);
        _ref = this.aria;
        for (attrib in _ref) {
          value = _ref[attrib];
          this.widget.setAttribute(attrib, value);
        }
        this.tapElement = this.options.getTapElement.call(this);
        this.dragElement = this.options.getDragElement.call(this);
        this.events = {
          tap: _SPL.onTap.bind(this),
          panstart: _SPL.onStart.bind(this),
          pan: _SPL.onMove.bind(this),
          panend: _SPL.onEnd.bind(this),
          pancancel: _SPL.onEnd.bind(this),
          keydown: _SPL.onKeydown.bind(this)
        };
        this.hammer = [
          {
            manager: new Hammer.Manager(this.tapElement),
            evento: new Hammer.Tap,
            methods: ['tap']
          }, {
            manager: new Hammer.Manager(this.dragElement, {
              dragLockToAxis: true,
              dragBlockHorizontal: true,
              preventDefault: true
            }),
            evento: new Hammer.Pan({
              direction: Hammer.DIRECTION_HORIZONTAL
            }),
            methods: ['panstart', 'pan', 'panend', 'pancancel']
          }
        ];
        _ref1 = this.hammer;
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          o = _ref1[_i];
          o.manager.add(o.evento);
          _ref2 = o.methods;
          for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
            m = _ref2[_j];
            o.manager.on(m, this.events[m]);
          }
        }
        this.widget.addEventListener('keydown', this.events.keydown, true);
        hasMutation = 'MutationObserver' in window;
        if (hasMutation) {
          that = this;
          observer = new MutationObserver(function(mutations) {
            mutations.forEach(function(mutation) {
              if (mutation.attributeName === 'class') {
                _SPL.observer.apply(that, [mutation.target]);
              }
            });
          });
          configObserver = {
            attributes: true,
            attributeOldValue: true
          };
          _ref3 = this.radios;
          for (_k = 0, _len2 = _ref3.length; _k < _len2; _k++) {
            radio = _ref3[_k];
            observer.observe(radio, configObserver);
          }
        }
        _SPL.onToggle.call(this);
      }
    };

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
      if (isElement(this.container === false)) {
        throw new SwitchSlideException('✖ Container must be an HTMLElement');
      } else {
        initialized = SwitchSlide.data(this.container);
        if (initialized instanceof SwitchSlide) {
          return initialized;
        } else {
          id = ++GUID;
          this.container.GUID = id;
          instances[id] = this;
          this.options = {
            labeledby: null,
            required: false,
            template: _SPL.getTemplate,
            setSizes: _SPL.setSizes,
            getElements: _SPL.getElements,
            getTapElement: _SPL.getTapElement,
            getDragElement: _SPL.getDragElement,
            negative: false,
            swapOrder: false,
            errorClass: 'frm__err',
            initialize: 'switchSlide--initialized',
            widget: '.widgetSlide',
            opts: '.widgetSlide__opt',
            optMin: '.widgetSlide__opt--min',
            optMax: '.widgetSlide__opt--max',
            knob: '.widgetSlide__knob'
          };
          extend(this.options, options);
          this.a = this.options.swapOrder ? 1 : 0;
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
            this.margin = 0;
            this.shift = null;
            if (this.radios[this.a].checked) {
              this.shift = false;
            }
            if (this.radios[this.b].checked) {
              this.shift = true;
            }
            this.valor = null;
            this.updateValor();
            this.active = null;
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
            this.eventToggleParams = [
              {
                'instance': this,
                'radios': this.radios,
                'value': this.valor
              }
            ];
            this.eventChange = new CustomEvent('change', {
              bubbles: true
            });
            this.eventClick = new CustomEvent('click', {
              bubbles: true
            });
            this.widget = this.sMin = this.sMax = this.knob = null;
            _SPL.build.call(this);
          }
        }
      }
      return;
    }

    SwitchSlide.prototype.emitToggle = function() {
      this.emitEvent('toggle', this.eventToggleParams);
    };

    SwitchSlide.prototype.swap = function(v) {
      this.shift = v != null ? v : !this.shift;
      _SPL.onToggle.call(this);
    };

    SwitchSlide.prototype.reset = function() {
      this.shift = null;
      _SPL.onToggle.call(this);
    };

    SwitchSlide.prototype.updateAria = function() {
      var v;
      if (this.shift !== null) {
        v = this.shift === true ? this.radios[this.b].title : this.radios[this.a].title;
        this.widget.setAttribute('aria-valuenow', v);
        this.widget.setAttribute('aria-valuetext', v);
      }
      v = null;
    };

    SwitchSlide.prototype.updateValor = function() {
      this.valor = null;
      if (this.shift !== null) {
        this.valor = this.shift === true ? this.radios[this.b].value : this.radios[this.a].value;
      }
      if (this.eventToggleParams != null) {
        this.eventToggleParams[0].value = this.valor;
      }
    };

    SwitchSlide.prototype.updatePosition = function() {
      var value;
      value = ["translate3d(" + this.transform.translate.x + "px, 0, 0)"];
      this.dragElement.style[transformProperty] = value.join(" ");
      value = null;
    };

    SwitchSlide.prototype.destroy = function() {
      var o, _i, _len, _ref;
      if (this.container !== null) {
        _ref = this.hammer;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          o = _ref[_i];
          o.manager.destroy();
        }
        this.widget.removeEventListener('keydown', this.events.keydown);
        removeAllChildren(this.widget);
        if (this.container.contains(this.widget)) {
          this.container.removeChild(this.widget);
        }
        classie.remove(this.container, this.options.initialize);
        this.container.removeAttribute('style');
        this.container.GUID = null;
        this.container = this.options = this.a = this.b = this.radios = this.width = this.margin = this.shift = this.valor = this.active = this.transform = this.keyCodes = this.aria = this.eventToggleParams = this.eventChange = this.widget = this.sMin = this.sMax = this.knob = this.sizes = this.tapElement = this.dragElement = this.events = this.hammer = null;
      }
    };

    return SwitchSlide;

  })();
  extend(SwitchSlide.prototype, EventEmitter.prototype);
  SwitchSlide.data = function(el) {
    var id;
    id = el && el.GUID;
    return id && instances[id];
  };
  return SwitchSlide;
});
