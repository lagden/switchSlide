switch.js - Switch Slide
==================================

It is a plugin that show `radios buttons` like switch slide

## Installation

    bower install switch-slide
    
#### Warning for IE

Required [CustomEvent](https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent#Polyfill) polyfill to avoid error.

## Usage

**Markup**

```html
<div id="labelSwitch">Did you think good?</div>
<div class="switchSlide">
    <label for="sim">Yep</label>
    <input id="sim" type="radio" title="Yep" name="switch" value="s">
    <label for="nao">Nope</label>
    <input id="nao" type="radio" title="Nope" name="switch" value="n">
</div>
```

**AMD**

```javascript
[].forEach.call(document.querySelectorAll('.switchSlide'), function(el, idx, arr) {
    require('switch-slide/switch')(el, false, el.previousElementSibling.id);
});
```

**Global**

```javascript
[].forEach.call(document.querySelectorAll('.switchRadio'), function(el, idx, arr) {
    new SwitchSlide(el, false, el.previousElementSibling.id);
});
```

## Author

[Thiago Lagden](http://lagden.in)