
/*
switch.js - SwitchSlide

It is a plugin that show `radios buttons` like slide switch

@author      Thiago Lagden <lagden [at] gmail.com>
@copyright   Author
 */
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

(function(root, factory) {
  if (typeof define === "function" && define.amd) {
    define(['get-style-property/get-style-property', 'classie/classie', 'eventEmitter/EventEmitter', 'draggabilly/draggabilly'], factory);
  } else {
    root.SwitchSlide = factory(root.getStyleProperty, root.classie, root.EventEmitter, root.Draggabilly);
  }
})(this, function(getStyleProperty, classie, EventEmitter, Draggabilly) {
  'use strict';
  var GUID, SwitchSlide, instances, transformProperty, _SPL;
  transformProperty = getStyleProperty('transform');
  GUID = 0;
  instances = {};
  _SPL = {
    getTemplate: function() {
      return ['<div class="switchSlide__opt switchSlide__opt--on"><span>{captionOn}</span></div>', '<div class="switchSlide__opt switchSlide__opt--off"><span>{captionOff}</span></div>', '<div class="switchSlide__knob"></div>'].join('');
    },
    onDragStart: function(draggieInstance, event, pointer) {
      return classie.add(draggieInstance.element, 'is-dragging');
    },
    onDragEnd: function(draggieInstance, event, pointer) {
      classie.remove(draggieInstance.element, 'is-dragging');
    },
    build: function() {
      var captionOff, captionOn, content, labels, r, sizes;
      captionOn = captionOff = '';
      labels = this.container.getElementsByTagName('label');
      if (labels.length === 2) {
        captionOn = labels[0].textContent;
        captionOff = labels[1].textContent;
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
      this.sOn = this.container.querySelector('.switchSlide__opt--on');
      this.sOff = this.container.querySelector('.switchSlide__opt--off');
      this.knob = this.container.querySelector('.switchSlide__knob');
      sizes = this.getSizes();
      this.size = Math.max(sizes.sOn, sizes.sOff);
      this.sOn.style.width = "" + this.size + "px";
      this.sOff.style.width = "" + this.size + "px";
      this.knob.style.width = "" + this.size + "px";
      this.knob.style.height = "" + sizes.cHeight + "px";
      this.container.style.width = (this.size * 2) + 'px';
      this.containerWidth = this.size * 2;
      this.draggie = new Draggabilly(this.knob, {
        containment: this.container,
        axis: 'x'
      });
      this.draggie.on('dragEnd', _SPL.onDragEnd.bind(this));
      this.eventChange = new CustomEvent('change');
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
        return null;
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
        return null;
      }
      this.template = _SPL.getTemplate();
      this.size = 0;
      this.side = null;
      if (this.radios[0].checked && !this.radios[1].checked) {
        this.side = false;
      }
      if (this.radios[1].checked && !this.radios[0].checked) {
        this.side = true;
      }
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
      _SPL.build.bind(this)();
    }

    SwitchSlide.prototype.toggle = function(v) {
      var radio, _i, _len, _ref;
      this.side = v !== void 0 ? v : this.side;
      if (this.side !== null) {
        this.active = true;
        this.transform.translate.x = this.side ? -this.size : 0;
        if (this.side) {
          this.radios[0].removeAttribute('checked');
          this.radios[0].checked = false;
          this.radios[1].setAttribute('checked', '');
          this.radios[1].checked = true;
        } else {
          this.radios[1].removeAttribute('checked');
          this.radios[1].checked = false;
          this.radios[0].setAttribute('checked', '');
          this.radios[0].checked = true;
        }
      } else {
        this.active = false;
        this.transform.translate.x = -this.size / 2;
        _ref = this.radios;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          radio = _ref[_i];
          radio.removeAttribute('checked');
          radio.checked = false;
        }
      }
      this.ariaAttr();
      this.captionsActive();
      this.requestUpdate();
    };

    SwitchSlide.prototype.swap = function(v) {
      v = v !== void 0 ? v : null;
      this.side = v !== null ? !v : !this.side;
      _SPL.onToggle.bind(this)();
    };

    SwitchSlide.prototype.reset = function() {
      this.side = null;
      _SPL.onToggle.bind(this)();
    };

    SwitchSlide.prototype.getSizes = function() {
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
        'sOff': sOff.clientWidth,
        'cHeight': clone.clientHeight
      };
      document.body.removeChild(clone);
      clone = null;
      return sizes;
    };

    SwitchSlide.prototype.ariaAttr = function() {
      var v;
      if (this.side === null) {
        v = this.side;
      } else {
        v = this.side ? this.radios[1].title : this.radios[0].title;
      }
      this.sFlex.setAttribute('aria-valuenow', v);
      this.sFlex.setAttribute('aria-valuetext', v);
    };

    SwitchSlide.prototype.valorUpdate = function() {
      var v;
      if (this.side === null) {
        v = this.side;
      } else {
        v = this.side ? this.radios[1].value : this.radios[0].value;
      }
      return v;
    };

    SwitchSlide.prototype.captionsActive = function() {
      var method;
      method = this.active ? 'add' : 'remove';
      classie[method](this.sOn, 'is-active');
      classie[method](this.sOff, 'is-active');
    };

    SwitchSlide.prototype.updateTransform = function() {
      var value;
      value = ["translate3d(" + this.transform.translate.x + "px, 0, 0)"];
      this.knob.style[transformProperty] = value.join(" ");
    };

    SwitchSlide.prototype.requestUpdate = function() {
      if (this.ticking === false) {
        this.ticking = true;
        requestAnimationFrame(this.updateTransform.bind(this));
      }
    };

    SwitchSlide.prototype.destroy = function() {
      var style;
      style = this.container.style;
      style.width = '';
      this.container.removeChild(this.sFlex);
      this.container.removeAttribute("data-sr" + this.container.srGUID);
      delete this.container.srGUID;
      this.sFlex = null;
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
