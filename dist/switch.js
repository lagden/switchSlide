
/*
switch.js - SwitchSlide

It is a plugin that show `radios buttons` like switch slide

@author      Thiago Lagden <lagden [at] gmail.com>
@copyright   Author
 */
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

(function(root, factory) {
  if (typeof define === "function" && define.amd) {
    define(['get-style-property/get-style-property', 'classie/classie', 'eventEmitter/EventEmitter', 'hammerjs/hammer'], factory);
  } else {
    root.SwitchSlide = factory(root.getStyleProperty, root.classie, root.EventEmitter, root.Hammer);
  }
})(this, function(getStyleProperty, classie, EventEmitter, Hammer) {
  'use strict';
  var GUID, SwitchSlide, instances, transformProperty, _SPL;
  transformProperty = getStyleProperty('transform');
  GUID = 0;
  instances = {};
  _SPL = {
    getTemplate: function() {
      return ['<div class="switchSlide__opt switchSlide__opt--off">', '<span>{captionOff}</span></div>', '<div class="switchSlide__opt switchSlide__opt--on">', '<span>{captionOn}</span></div>', '<div class="switchSlide__knob"></div>'].join('');
    },
    getSizes: function() {
      var clone, sOff, sOffSelector, sOn, sOnSelector, sizes;
      clone = this.container.cloneNode(true);
      clone.style.visibility = 'hidden';
      clone.style.position = 'absolute';
      document.body.appendChild(clone);
      sOnSelector = '.switchSlide__opt--on';
      sOffSelector = '.switchSlide__opt--off';
      sOn = clone.querySelector(sOnSelector);
      sOff = clone.querySelector(sOffSelector);
      sizes = {
        'sOn': sOn.clientWidth,
        'sOff': sOff.clientWidth
      };
      document.body.removeChild(clone);
      clone = null;
      return sizes;
    },
    onToggle: function() {
      var radio, _i, _len, _ref;
      this.toggle();
      this.emitEvent('toggle', this.eventToggleParam);
      _ref = this.radios;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        radio = _ref[_i];
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
      var v;
      v = (this.size / 2) + event.deltaX;
      if (this.ligado !== null) {
        v = this.ligado ? this.size + event.deltaX : event.deltaX;
      }
      this.transform.translate.x = Math.min(this.size, Math.max(v, 0));
      this.updatePosition();
    },
    onEnd: function(el, event) {
      this.ligado = Math.abs(this.transform.translate.x) > (this.size / 2);
      classie.remove(el, 'is-dragging');
      _SPL.onToggle.call(this);
    },
    onTap: function(el, event) {
      var center, rect;
      rect = el.getBoundingClientRect();
      center = rect.left + (rect.width / 2);
      this.ligado = event.center.x > center;
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
          this.ligado = true;
          dispara = true;
          break;
        case this.keyCodes.left:
          this.ligado = false;
          dispara = true;
      }
      if (dispara) {
        _SPL.onToggle.call(this);
      }
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
      var captionOff, captionOn, content, el, labels, pan, r, sizes, tap, _i, _len, _ref;
      captionOn = captionOff = '';
      labels = this.container.getElementsByTagName('label');
      if (labels.length === 2) {
        captionOff = labels[0].textContent;
        captionOn = labels[1].textContent;
      } else {
        console.warn('✖ No labels');
      }
      r = {
        'captionOn': captionOn,
        'captionOff': captionOff
      };
      content = this.template.replace(/\{(.*?)\}/g, function(a, b) {
        return r[b];
      });
      this.container.insertAdjacentHTML('afterbegin', content);
      this.elements = [];
      sizes = _SPL.getSizes.call(this);
      this.size = Math.max(sizes.sOn, sizes.sOff);
      this.sOn = this.container.querySelector('.switchSlide__opt--on');
      this.sOff = this.container.querySelector('.switchSlide__opt--off');
      this.drag = this.container.querySelector('.switchSlide__knob');
      this.elements.push(this.sOn);
      this.elements.push(this.sOff);
      this.elements.push(this.drag);
      _ref = this.elements;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        el = _ref[_i];
        el.style.width = "" + this.size + "px";
      }
      this.container.style.width = (this.size * 2) + 'px';
      _SPL.aria.call(this, this.container);
      tap = new Hammer.Tap;
      this.mc = new Hammer.Manager(this.container, {
        dragLockToAxis: true,
        dragBlockHorizontal: true,
        preventDefault: true
      });
      this.mc.add(tap);
      this.mc.on('tap', _SPL.onTap.bind(this, this.container));
      pan = new Hammer.Pan({
        direction: Hammer.DIRECTION_HORIZONTAL
      });
      this.mk = new Hammer.Manager(this.drag, {
        dragLockToAxis: true,
        dragBlockHorizontal: true,
        preventDefault: true
      });
      this.mk.add(pan);
      this.mk.on('panstart', _SPL.onStart.bind(this, this.drag));
      this.mk.on('pan', _SPL.onMove.bind(this));
      this.mk.on('panend', _SPL.onEnd.bind(this, this.drag));
      this.mk.on('pancancel', _SPL.onEnd.bind(this, this.drag));
      this.eventCall = {
        'keydown': _SPL.onKeydown.bind(this)
      };
      this.container.addEventListener('keydown', this.eventCall.keydown);
      _SPL.onToggle.call(this);
    },
    initCheck: function(container) {
      var attrib, attribs, data, regex, _i, _len;
      regex = /data-sr(\d+)/i;
      attribs = container.attributes;
      for (_i = 0, _len = attribs.length; _i < _len; _i++) {
        attrib = attribs[_i];
        if (regex.test(attrib.name)) {
          data = attrib.name;
        }
      }
      if (!!data) {
        return true;
      }
    }
  };
  SwitchSlide = (function(_super) {
    __extends(SwitchSlide, _super);

    function SwitchSlide(container, required, labeledby) {
      var id, idx, radio, radios, _i, _len;
      if (false === (this instanceof SwitchSlide)) {
        return new SwitchSlide(container, required, labeledby);
      }
      labeledby = labeledby || null;
      required = required || false;
      if (_SPL.initCheck(container)) {
        console.warn('The component has been initialized.');
        return;
      } else {
        id = ++GUID;
        this.container = container;
        this.container.srGUID = id;
        instances[id] = this;
        container.setAttribute("data-sr" + id, '');
      }
      this.radios = [];
      radios = this.container.getElementsByTagName('input');
      for (idx = _i = 0, _len = radios.length; _i < _len; idx = ++_i) {
        radio = radios[idx];
        if (!(radio.type === 'radio')) {
          continue;
        }
        radio.setAttribute('data-side', idx);
        this.radios.push(radio);
      }
      if (this.radios.length !== 2) {
        console.err('✖ No radios');
        return;
      }
      this.template = _SPL.getTemplate();
      this.size = 0;
      this.ligado = null;
      if (this.radios[0].checked && !this.radios[1].checked) {
        this.ligado = false;
      }
      if (this.radios[1].checked && !this.radios[0].checked) {
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
        'aria-valuemin': this.radios[0].title,
        'aria-valuemax': this.radios[1].title,
        'aria-valuetext': null,
        'aria-valuenow': null,
        'aria-labeledby': labeledby,
        'aria-required': required
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

    SwitchSlide.prototype.toggle = function(v) {
      var a, b, radio, _i, _len, _ref;
      v = v || false;
      if (v !== false) {
        this.ligado = v;
      }
      if (this.ligado !== null) {
        this.active = true;
        this.transform.translate.x = this.ligado ? this.size : 0;
        a = this.ligado ? 1 : 0;
        b = a ^ 1;
        _SPL.checked(this.radios[a]);
        _SPL.unchecked(this.radios[b]);
      } else {
        this.active = false;
        this.transform.translate.x = this.size / 2;
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
    };

    SwitchSlide.prototype.swap = function(v) {
      if (v != null) {
        this.ligado = v;
      }
      this.ligado = !this.ligado;
      _SPL.onToggle.call(this);
    };

    SwitchSlide.prototype.reset = function() {
      this.ligado = null;
      _SPL.onToggle.call(this);
    };

    SwitchSlide.prototype.isActive = function() {
      var method;
      method = this.active ? 'add' : 'remove';
      classie[method](this.drag, 'is-active');
    };

    SwitchSlide.prototype.updateAria = function() {
      var v;
      if (this.ligado !== null) {
        v = this.ligado === true ? this.radios[1].title : this.radios[0].title;
        this.container.setAttribute('aria-valuenow', v);
        this.container.setAttribute('aria-valuetext', v);
      }
    };

    SwitchSlide.prototype.updateValor = function() {
      this.valor = null;
      if (this.ligado !== null) {
        this.valor = this.ligado === true ? this.radios[1].value : this.radios[0].value;
      }
      if (this.eventToggleParam != null) {
        this.eventToggleParam[0].value = this.valor;
      }
    };

    SwitchSlide.prototype.updatePosition = function() {
      var value;
      value = ["translate3d(" + this.transform.translate.x + "px, 0, 0)"];
      this.drag.style[transformProperty] = value.join(" ");
    };

    SwitchSlide.prototype.destroy = function() {
      var attr, el, radio, _i, _j, _len, _len1, _ref, _ref1;
      if (this.container !== null) {
        _ref = this.radios;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          radio = _ref[_i];
          radio.removeAttribute('data-side');
        }
        this.container.removeEventListener('keydown', this.eventCall.keydown);
        this.mk.destroy();
        this.mc.destroy();
        _ref1 = this.elements;
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          el = _ref1[_j];
          this.container.removeChild(el);
        }
        for (attr in this.aria) {
          this.container.removeAttribute(attr);
        }
        this.container.removeAttribute("class");
        this.container.removeAttribute("style");
        this.container.removeAttribute("data-sr" + this.container.srGUID);
        delete this.container.srGUID;
        this.container = null;
      }
    };

    return SwitchSlide;

  })(EventEmitter);
  SwitchSlide.data = function(el) {
    var id;
    id = el && el.srGUID;
    return id && instances[id];
  };
  return SwitchSlide;
});
