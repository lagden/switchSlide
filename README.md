switch.js - Switch Slide
==================================

The plugin show `radios buttons` like switch slide

## Installation

    bower install switch-slide

#### Warning for IE

Required [CustomEvent](https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent#Polyfill) polyfill to avoid error.

## Options

```Coffee
labeledby      : null
required       : false
template       : _SPL.getTemplate
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
```

## Usage

**Markup**

```html
<div id="labelSwitch">Did you think good?</div>
<div class="switchSlide">
    <label for="nope">Nope</label><input id="nope" type="radio" title="Nope" name="isGood" value="n">
    <label for="yepi">Yepi</label><input id="yepi" type="radio" title="Yepi" name="isGood" value="y">
</div>
```

**AMD**

```javascript
require('switch-slide/switch')('.switchSlide');
```

**Global**

```javascript
new SwitchSlide('.switchSlide');
```

**Custom**
```javascript
try {
    var el = document.querySelector('.switchCustom');
    sr = new SwitchSlide(el, {
        required: el.previousElementSibling.id,
        negative: true,
        swap: true,
        initialize: 'switchCustom--initialized',
        getTapElement: function() {
            return this.container
        },
        getDragElement: function() {
            return this.widget
        },
        setSizes: function() {
            this.sMax.style.width =
            this.sMin.style.width = this.width + "px";
            this.widget.style.width = (this.width * 2) + this.sizes.knob + 'px'
            this.container.style.width = this.width + this.sizes.knob + 'px'
        }
    });
    cacheSwitches.push(sr);
} catch (e) {
    console.error('sr', e.message, e.name);
}
```

## Author

[Thiago Lagden](http://lagden.in)

::beers::
