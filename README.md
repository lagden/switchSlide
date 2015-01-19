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

## Unlicense

This project used to be released under MIT, but I release everything under the [Unlicense][] now. Here's the gist of it but you can find the full thing in the `UNLICENSE` file.

>This is free and unencumbered software released into the public domain.
>
>Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

## Author

[Thiago Lagden](http://lagden.in)

::beers::
