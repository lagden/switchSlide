switch.js - Switch Slide
========================

The plugin transform `radios buttons` in `switch`

## Installation

    bower install switch-slide

#### Warning for IE

Required [CustomEvent](https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent#Polyfill) polyfill to avoid error.

## Options

```Coffee
labeledby      : null
required       : false
template       : _SPL.getTemplate
setSizes       : _SPL.setSizes
getElements    : _SPL.getElements
getTapElement  : _SPL.getTapElement
getDragElement : _SPL.getDragElement
negative       : false
swapOrder      : false
errorClass     : 'frm__err'
initialize     : ''
widget         : ''
opts           : ''
optMin         : ''
optMax         : ''
knob           : ''
```

## Usage

### Markup

```html
<div id="labelSwitch" class="label">Did you like?</div>
<div class="switchSlide">
    <label for="no">No</label>
    <input id="no" type="radio" title="No" name="switch" value="N">
    <label for="yes">Yes</label>
    <input id="yes" type="radio" title="Yes" name="switch" value="S" checked>
</div>
```

### Javascript

##### Basic

```javascript
var sl = SwitchSlide('.switchSlide');
```

##### Custom

Use the same markup

```javascript
var el = document.querySelector('.switchSlide');
sr = SwitchSlide(el, {
    required: el.previousElementSibling.id,
    negative: true,
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
```

## Author

[Thiago Lagden](https://github.com/lagden)

::beers::
