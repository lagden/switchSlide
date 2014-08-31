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
    <label for="nope">Nope</label>
    <input id="nope" type="radio" title="Nope" name="good" value="n">
    <label for="yepi">Yepi</label>
    <input id="yepi" type="radio" title="Yepi" name="good" value="y">
</div>
```

**AMD**

```javascript
[].forEach.call(document.querySelectorAll('.switchSlide'), function(el, idx, arr) {
    require('switch-slide/switch')(el);
});
```

**Global**

```javascript
[].forEach.call(document.querySelectorAll('.switchSlide'), function(el, idx, arr) {
    new SwitchSlide(el);
});
```

## Author

[Thiago Lagden](http://lagden.in)