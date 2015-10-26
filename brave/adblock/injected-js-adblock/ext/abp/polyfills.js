/*! https://mths.be/endswith v0.2.0 by @mathias */
if (!String.prototype.endsWith) {
  (function() {
    'use strict'; // needed to support `apply`/`call` with `undefined`/`null`
    var defineProperty = (function() {
      // IE 8 only supports `Object.defineProperty` on DOM elements
      try {
        var object = {};
        var $defineProperty = Object.defineProperty;
        var result = $defineProperty(object, object, object) && $defineProperty;
      } catch (error) {}
      return result;
    }());
    var toString = {}.toString;
    var endsWith = function(search) {
      if (this == null) {
        throw TypeError();
      }
      var string = String(this);
      if (search && toString.call(search) == '[object RegExp]') {
        throw TypeError();
      }
      var stringLength = string.length;
      var searchString = String(search);
      var searchLength = searchString.length;
      var pos = stringLength;
      if (arguments.length > 1) {
        var position = arguments[1];
        if (position !== undefined) {
          // `ToInteger`
          pos = position ? Number(position) : 0;
          if (pos != pos) { // better `isNaN`
            pos = 0;
          }
        }
      }
      var end = Math.min(Math.max(pos, 0), stringLength);
      var start = end - searchLength;
      if (start < 0) {
        return false;
      }
      var index = -1;
      while (++index < searchLength) {
        if (string.charCodeAt(start + index) != searchString.charCodeAt(index)) {
          return false;
        }
      }
      return true;
    };
    if (defineProperty) {
      defineProperty(String.prototype, 'endsWith', {
        'value': endsWith,
        'configurable': true,
        'writable': true
        });
    } else {
      String.prototype.endsWith = endsWith;
    }
  }());
}

var Symbol;
if (!Symbol) {
  Symbol = (function(Object) {

    // (C) WebReflection Mit Style License

    var ObjectPrototype = Object.prototype,
    defineProperty = Object.defineProperty,
    prefix = '__simbol' + Math.random() + '__',
    id = 0;

    function get() { /*avoid set w/out get prob*/ }

    function Symbol() {
      var __symbol__ = prefix + id++;
      defineProperty(
        ObjectPrototype,
        this._ = __symbol__, {
      enumerable: false,
      configurable: false,
      get: get, // undefined
      set: function(value) {
        defineProperty(this, __symbol__, {
        enumerable: false,
        configurable: true,
        writable: true,
        value: value
          });
      }
        }
        );
    }

    defineProperty(Symbol.prototype, 'toString', {
    enumerable: false,
    configurable: false,
    writable: false,
    value: function toString() {
      return this._;
      }
      });

    return Symbol;

  }(Object));
}

/*! https://mths.be/startswith v0.2.0 by @mathias */
if (!String.prototype.startsWith) {
  (function() {
    'use strict'; // needed to support `apply`/`call` with `undefined`/`null`
    var defineProperty = (function() {
      // IE 8 only supports `Object.defineProperty` on DOM elements
      try {
        var object = {};
        var $defineProperty = Object.defineProperty;
        var result = $defineProperty(object, object, object) && $defineProperty;
      } catch (error) {}
      return result;
    }());
    var toString = {}.toString;
    var startsWith = function(search) {
      if (this == null) {
        throw TypeError();
      }
      var string = String(this);
      if (search && toString.call(search) == '[object RegExp]') {
        throw TypeError();
      }
      var stringLength = string.length;
      var searchString = String(search);
      var searchLength = searchString.length;
      var position = arguments.length > 1 ? arguments[1] : undefined;
      // `ToInteger`
      var pos = position ? Number(position) : 0;
      if (pos != pos) { // better `isNaN`
        pos = 0;
      }
      var start = Math.min(Math.max(pos, 0), stringLength);
      // Avoid the `indexOf` call if no match is possible
      if (searchLength + start > stringLength) {
        return false;
      }
      var index = -1;
      while (++index < searchLength) {
        if (string.charCodeAt(start + index) != searchString.charCodeAt(index)) {
          return false;
        }
      }
      return true;
    };
    if (defineProperty) {
      defineProperty(String.prototype, 'startsWith', {
        'value': startsWith,
        'configurable': true,
        'writable': true
        });
    } else {
      String.prototype.startsWith = startsWith;
    }
  }());
}

(function(exports) {
  'use strict';
  //shared pointer
  var i;
  //shortcuts
  var defineProperty = Object.defineProperty,
  is = function(a, b) {
    return isNaN(a) ? isNaN(b) : a === b;
  };


  //Polyfill global objects
  if (typeof WeakMap == 'undefined') {
    exports.WeakMap = createCollection({
      // WeakMap#delete(key:void*):boolean
      'delete': sharedDelete,
      // WeakMap#clear():
    clear: sharedClear,
      // WeakMap#get(key:void*):void*
    get: sharedGet,
      // WeakMap#has(key:void*):boolean
    has: mapHas,
      // WeakMap#set(key:void*, value:void*):void
    set: sharedSet
      }, true);
  }

  if (typeof Map == 'undefined' || typeof((new Map).values) !== 'function' || !(new Map).values().next) {
    exports.Map = createCollection({
      // WeakMap#delete(key:void*):boolean
      'delete': sharedDelete,
      //:was Map#get(key:void*[, d3fault:void*]):void*
      // Map#has(key:void*):boolean
    has: mapHas,
      // Map#get(key:void*):boolean
    get: sharedGet,
      // Map#set(key:void*, value:void*):void
    set: sharedSet,
      // Map#keys(void):Iterator
    keys: sharedKeys,
      // Map#values(void):Iterator
    values: sharedValues,
      // Map#entries(void):Iterator
    entries: mapEntries,
      // Map#forEach(callback:Function, context:void*):void ==> callback.call(context, key, value, mapObject) === not in specs`
    forEach: sharedForEach,
      // Map#clear():
    clear: sharedClear
      });
  }

  if (typeof Set == 'undefined' || typeof((new Set).values) !== 'function' || !(new Set).values().next) {
    exports.Set = createCollection({
      // Set#has(value:void*):boolean
    has: setHas,
      // Set#add(value:void*):boolean
    add: sharedAdd,
      // Set#delete(key:void*):boolean
      'delete': sharedDelete,
      // Set#clear():
    clear: sharedClear,
      // Set#keys(void):Iterator
    keys: sharedValues, // specs actually say "the same function object as the initial value of the values property"
      // Set#values(void):Iterator
    values: sharedValues,
      // Set#entries(void):Iterator
    entries: setEntries,
      // Set#forEach(callback:Function, context:void*):void ==> callback.call(context, value, index) === not in specs
    forEach: sharedForEach
      });
  }

  if (typeof WeakSet == 'undefined') {
    exports.WeakSet = createCollection({
      // WeakSet#delete(key:void*):boolean
      'delete': sharedDelete,
      // WeakSet#add(value:void*):boolean
    add: sharedAdd,
      // WeakSet#clear():
    clear: sharedClear,
      // WeakSet#has(value:void*):boolean
    has: setHas
      }, true);
  }


  /**
   * ES6 collection constructor
   * @return {Function} a collection class
   */
  function createCollection(proto, objectOnly) {
    function Collection(a) {
      if (!this || this.constructor !== Collection) return new Collection(a);
      this._keys = [];
      this._values = [];
      this._itp = []; // iteration pointers
      this.objectOnly = objectOnly;

      //parse initial iterable argument passed
      if (a) init.call(this, a);
    }

    //define size for non object-only collections
    if (!objectOnly) {
      defineProperty(proto, 'size', {
      get: sharedSize
        });
    }

    //set prototype
    proto.constructor = Collection;
    Collection.prototype = proto;

    return Collection;
  }


  /** parse initial iterable argument passed */
  function init(a) {
    var i;
    //init Set argument, like `[1,2,3,{}]`
    if (this.add)
      a.forEach(this.add, this);
    //init Map argument like `[[1,2], [{}, 4]]`
    else
      a.forEach(function(a) {
        this.set(a[0], a[1])
      }, this);
  }


  /** delete */
  function sharedDelete(key) {
    if (this.has(key)) {
      this._keys.splice(i, 1);
      this._values.splice(i, 1);
      // update iteration pointers
      this._itp.forEach(function(p) {
        if (i < p[0]) p[0]--;
      });
    }
    // Aurora here does it while Canary doesn't
    return -1 < i;
  };

  function sharedGet(key) {
    return this.has(key) ? this._values[i] : undefined;
  }

  function has(list, key) {
    if (this.objectOnly && key !== Object(key))
      throw new TypeError("Invalid value used as weak collection key");
    //NaN or 0 passed
    if (key != key || key === 0)
      for (i = list.length; i-- && !is(list[i], key);) {} else i = list.indexOf(key);
    return -1 < i;
  }

  function setHas(value) {
    return has.call(this, this._values, value);
  }

  function mapHas(value) {
    return has.call(this, this._keys, value);
  }

  /** @chainable */
  function sharedSet(key, value) {
    this.has(key) ?
    this._values[i] = value :
    this._values[this._keys.push(key) - 1] = value;
    return this;
  }

  /** @chainable */
  function sharedAdd(value) {
    if (!this.has(value)) this._values.push(value);
    return this;
  }

  function sharedClear() {
    (this._keys || 0).length =
    this._values.length = 0;
  }

  /** keys, values, and iterate related methods */
  function sharedKeys() {
    return sharedIterator(this._itp, this._keys);
  }

  function sharedValues() {
    return sharedIterator(this._itp, this._values);
  }

  function mapEntries() {
    return sharedIterator(this._itp, this._keys, this._values);
  }

  function setEntries() {
    return sharedIterator(this._itp, this._values, this._values);
  }

  function sharedIterator(itp, array, array2) {
    var p = [0],
    done = false;
    itp.push(p);
    return {
    next: function() {
      var v, k = p[0];
      if (!done && k < array.length) {
        v = array2 ? [array[k], array2[k]] : array[k];
        p[0]++;
      } else {
        done = true;
        itp.splice(itp.indexOf(p), 1);
      }
      return {
      done: done,
      value: v
      };
    }
    };
  }

  function sharedSize() {
    return this._values.length;
  }

  function sharedForEach(callback, context) {
    var it = this.entries();
    for (;;) {
      var r = it.next();
      if (r.done) break;
      callback.call(context, r.value[1], r.value[0], this);
    }
  }

})(typeof exports != 'undefined' && typeof global != 'undefined' ? global : this);