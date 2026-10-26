// Vendored from npm: web-jsbridge@1.0.3 (https://www.npmjs.com/package/web-jsbridge), MIT.
// Bundled with esbuild (--bundle --format=iife --global-name=WebJSBridge) to inline its
// eventemitter2 dependency into one self-contained script — the WebView whitelist a mini
// app runs in can block a CDN fetch silently and blank the page, so this can't be pinned
// to a CDN (see docs/patterns/bank-mini-app-integration.md). Upstream ships this minified
// and obfuscated (javascript-obfuscator) already; not re-formatted here so it stays a
// faithful copy of the published build.
var WebJSBridge = (() => {
  var __create = Object.create;
  var __defProp = Object.defineProperty;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __getProtoOf = Object.getPrototypeOf;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __commonJS = (cb, mod) => function __require() {
    try {
      return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
    } catch (e) {
      throw mod = 0, e;
    }
  };
  var __export = (target, all) => {
    for (var name in all)
      __defProp(target, name, { get: all[name], enumerable: true });
  };
  var __copyProps = (to, from, except, desc) => {
    if (from && typeof from === "object" || typeof from === "function") {
      for (let key of __getOwnPropNames(from))
        if (!__hasOwnProp.call(to, key) && key !== except)
          __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
    }
    return to;
  };
  var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
    // If the importer is in node compatibility mode or this is not an ESM
    // file that has been converted to a CommonJS file using a Babel-
    // compatible transform (i.e. "__esModule" has not been set), then set
    // "default" to the CommonJS "module.exports" for node compatibility.
    isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
    mod
  ));
  var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

  // node_modules/eventemitter2/lib/eventemitter2.js
  var require_eventemitter2 = __commonJS({
    "node_modules/eventemitter2/lib/eventemitter2.js"(exports, module) {
      !(function(undefined2) {
        var hasOwnProperty = Object.hasOwnProperty;
        var isArray = Array.isArray ? Array.isArray : function _isArray(obj) {
          return Object.prototype.toString.call(obj) === "[object Array]";
        };
        var defaultMaxListeners = 10;
        var nextTickSupported = typeof process == "object" && typeof process.nextTick == "function";
        var symbolsSupported = typeof Symbol === "function";
        var reflectSupported = typeof Reflect === "object";
        var setImmediateSupported = typeof setImmediate === "function";
        var _setImmediate = setImmediateSupported ? setImmediate : setTimeout;
        var ownKeys = symbolsSupported ? reflectSupported && typeof Reflect.ownKeys === "function" ? Reflect.ownKeys : function(obj) {
          var arr = Object.getOwnPropertyNames(obj);
          arr.push.apply(arr, Object.getOwnPropertySymbols(obj));
          return arr;
        } : Object.keys;
        function init() {
          this._events = {};
          if (this._conf) {
            configure.call(this, this._conf);
          }
        }
        function configure(conf) {
          if (conf) {
            this._conf = conf;
            conf.delimiter && (this.delimiter = conf.delimiter);
            if (conf.maxListeners !== undefined2) {
              this._maxListeners = conf.maxListeners;
            }
            conf.wildcard && (this.wildcard = conf.wildcard);
            conf.newListener && (this._newListener = conf.newListener);
            conf.removeListener && (this._removeListener = conf.removeListener);
            conf.verboseMemoryLeak && (this.verboseMemoryLeak = conf.verboseMemoryLeak);
            conf.ignoreErrors && (this.ignoreErrors = conf.ignoreErrors);
            if (this.wildcard) {
              this.listenerTree = {};
            }
          }
        }
        function logPossibleMemoryLeak(count, eventName) {
          var errorMsg = "(node) warning: possible EventEmitter memory leak detected. " + count + " listeners added. Use emitter.setMaxListeners() to increase limit.";
          if (this.verboseMemoryLeak) {
            errorMsg += " Event name: " + eventName + ".";
          }
          if (typeof process !== "undefined" && process.emitWarning) {
            var e = new Error(errorMsg);
            e.name = "MaxListenersExceededWarning";
            e.emitter = this;
            e.count = count;
            process.emitWarning(e);
          } else {
            console.error(errorMsg);
            if (console.trace) {
              console.trace();
            }
          }
        }
        var toArray = function(a, b, c) {
          var n = arguments.length;
          switch (n) {
            case 0:
              return [];
            case 1:
              return [a];
            case 2:
              return [a, b];
            case 3:
              return [a, b, c];
            default:
              var arr = new Array(n);
              while (n--) {
                arr[n] = arguments[n];
              }
              return arr;
          }
        };
        function toObject(keys, values) {
          var obj = {};
          var key;
          var len = keys.length;
          var valuesCount = values ? values.length : 0;
          for (var i = 0; i < len; i++) {
            key = keys[i];
            obj[key] = i < valuesCount ? values[i] : undefined2;
          }
          return obj;
        }
        function TargetObserver(emitter2, target, options) {
          this._emitter = emitter2;
          this._target = target;
          this._listeners = {};
          this._listenersCount = 0;
          var on, off;
          if (options.on || options.off) {
            on = options.on;
            off = options.off;
          }
          if (target.addEventListener) {
            on = target.addEventListener;
            off = target.removeEventListener;
          } else if (target.addListener) {
            on = target.addListener;
            off = target.removeListener;
          } else if (target.on) {
            on = target.on;
            off = target.off;
          }
          if (!on && !off) {
            throw Error("target does not implement any known event API");
          }
          if (typeof on !== "function") {
            throw TypeError("on method must be a function");
          }
          if (typeof off !== "function") {
            throw TypeError("off method must be a function");
          }
          this._on = on;
          this._off = off;
          var _observers = emitter2._observers;
          if (_observers) {
            _observers.push(this);
          } else {
            emitter2._observers = [this];
          }
        }
        Object.assign(TargetObserver.prototype, {
          subscribe: function(event, localEvent, reducer) {
            var observer = this;
            var target = this._target;
            var emitter2 = this._emitter;
            var listeners = this._listeners;
            var handler = function() {
              var args = toArray.apply(null, arguments);
              var eventObj = {
                data: args,
                name: localEvent,
                original: event
              };
              if (reducer) {
                var result = reducer.call(target, eventObj);
                if (result !== false) {
                  emitter2.emit.apply(emitter2, [eventObj.name].concat(args));
                }
                return;
              }
              emitter2.emit.apply(emitter2, [localEvent].concat(args));
            };
            if (listeners[event]) {
              throw Error("Event '" + event + "' is already listening");
            }
            this._listenersCount++;
            if (emitter2._newListener && emitter2._removeListener && !observer._onNewListener) {
              this._onNewListener = function(_event) {
                if (_event === localEvent && listeners[event] === null) {
                  listeners[event] = handler;
                  observer._on.call(target, event, handler);
                }
              };
              emitter2.on("newListener", this._onNewListener);
              this._onRemoveListener = function(_event) {
                if (_event === localEvent && !emitter2.hasListeners(_event) && listeners[event]) {
                  listeners[event] = null;
                  observer._off.call(target, event, handler);
                }
              };
              listeners[event] = null;
              emitter2.on("removeListener", this._onRemoveListener);
            } else {
              listeners[event] = handler;
              observer._on.call(target, event, handler);
            }
          },
          unsubscribe: function(event) {
            var observer = this;
            var listeners = this._listeners;
            var emitter2 = this._emitter;
            var handler;
            var events;
            var off = this._off;
            var target = this._target;
            var i;
            if (event && typeof event !== "string") {
              throw TypeError("event must be a string");
            }
            function clearRefs() {
              if (observer._onNewListener) {
                emitter2.off("newListener", observer._onNewListener);
                emitter2.off("removeListener", observer._onRemoveListener);
                observer._onNewListener = null;
                observer._onRemoveListener = null;
              }
              var index = findTargetIndex.call(emitter2, observer);
              emitter2._observers.splice(index, 1);
            }
            if (event) {
              handler = listeners[event];
              if (!handler) return;
              off.call(target, event, handler);
              delete listeners[event];
              if (!--this._listenersCount) {
                clearRefs();
              }
            } else {
              events = ownKeys(listeners);
              i = events.length;
              while (i-- > 0) {
                event = events[i];
                off.call(target, event, listeners[event]);
              }
              this._listeners = {};
              this._listenersCount = 0;
              clearRefs();
            }
          }
        });
        function resolveOptions(options, schema, reducers, allowUnknown) {
          var computedOptions = Object.assign({}, schema);
          if (!options) return computedOptions;
          if (typeof options !== "object") {
            throw TypeError("options must be an object");
          }
          var keys = Object.keys(options);
          var length = keys.length;
          var option, value;
          var reducer;
          function reject(reason) {
            throw Error('Invalid "' + option + '" option value' + (reason ? ". Reason: " + reason : ""));
          }
          for (var i = 0; i < length; i++) {
            option = keys[i];
            if (!allowUnknown && !hasOwnProperty.call(schema, option)) {
              throw Error('Unknown "' + option + '" option');
            }
            value = options[option];
            if (value !== undefined2) {
              reducer = reducers[option];
              computedOptions[option] = reducer ? reducer(value, reject) : value;
            }
          }
          return computedOptions;
        }
        function constructorReducer(value, reject) {
          if (typeof value !== "function" || !value.hasOwnProperty("prototype")) {
            reject("value must be a constructor");
          }
          return value;
        }
        function makeTypeReducer(types) {
          var message = "value must be type of " + types.join("|");
          var len = types.length;
          var firstType = types[0];
          var secondType = types[1];
          if (len === 1) {
            return function(v, reject) {
              if (typeof v === firstType) {
                return v;
              }
              reject(message);
            };
          }
          if (len === 2) {
            return function(v, reject) {
              var kind = typeof v;
              if (kind === firstType || kind === secondType) return v;
              reject(message);
            };
          }
          return function(v, reject) {
            var kind = typeof v;
            var i = len;
            while (i-- > 0) {
              if (kind === types[i]) return v;
            }
            reject(message);
          };
        }
        var functionReducer = makeTypeReducer(["function"]);
        var objectFunctionReducer = makeTypeReducer(["object", "function"]);
        function makeCancelablePromise(Promise2, executor, options) {
          var isCancelable;
          var callbacks;
          var timer = 0;
          var subscriptionClosed;
          var promise = new Promise2(function(resolve, reject, onCancel) {
            options = resolveOptions(options, {
              timeout: 0,
              overload: false
            }, {
              timeout: function(value, reject2) {
                value *= 1;
                if (typeof value !== "number" || value < 0 || !Number.isFinite(value)) {
                  reject2("timeout must be a positive number");
                }
                return value;
              }
            });
            isCancelable = !options.overload && typeof Promise2.prototype.cancel === "function" && typeof onCancel === "function";
            function cleanup() {
              if (callbacks) {
                callbacks = null;
              }
              if (timer) {
                clearTimeout(timer);
                timer = 0;
              }
            }
            var _resolve = function(value) {
              cleanup();
              resolve(value);
            };
            var _reject = function(err) {
              cleanup();
              reject(err);
            };
            if (isCancelable) {
              executor(_resolve, _reject, onCancel);
            } else {
              callbacks = [function(reason) {
                _reject(reason || Error("canceled"));
              }];
              executor(_resolve, _reject, function(cb) {
                if (subscriptionClosed) {
                  throw Error("Unable to subscribe on cancel event asynchronously");
                }
                if (typeof cb !== "function") {
                  throw TypeError("onCancel callback must be a function");
                }
                callbacks.push(cb);
              });
              subscriptionClosed = true;
            }
            if (options.timeout > 0) {
              timer = setTimeout(function() {
                var reason = Error("timeout");
                reason.code = "ETIMEDOUT";
                timer = 0;
                promise.cancel(reason);
                reject(reason);
              }, options.timeout);
            }
          });
          if (!isCancelable) {
            promise.cancel = function(reason) {
              if (!callbacks) {
                return;
              }
              var length = callbacks.length;
              for (var i = 1; i < length; i++) {
                callbacks[i](reason);
              }
              callbacks[0](reason);
              callbacks = null;
            };
          }
          return promise;
        }
        function findTargetIndex(observer) {
          var observers = this._observers;
          if (!observers) {
            return -1;
          }
          var len = observers.length;
          for (var i = 0; i < len; i++) {
            if (observers[i]._target === observer) return i;
          }
          return -1;
        }
        function searchListenerTree(handlers, type, tree, i, typeLength) {
          if (!tree) {
            return null;
          }
          if (i === 0) {
            var kind = typeof type;
            if (kind === "string") {
              var ns, n, l = 0, j = 0, delimiter = this.delimiter, dl = delimiter.length;
              if ((n = type.indexOf(delimiter)) !== -1) {
                ns = new Array(5);
                do {
                  ns[l++] = type.slice(j, n);
                  j = n + dl;
                } while ((n = type.indexOf(delimiter, j)) !== -1);
                ns[l++] = type.slice(j);
                type = ns;
                typeLength = l;
              } else {
                type = [type];
                typeLength = 1;
              }
            } else if (kind === "object") {
              typeLength = type.length;
            } else {
              type = [type];
              typeLength = 1;
            }
          }
          var listeners = null, branch, xTree, xxTree, isolatedBranch, endReached, currentType = type[i], nextType = type[i + 1], branches, _listeners;
          if (i === typeLength) {
            if (tree._listeners) {
              if (typeof tree._listeners === "function") {
                handlers && handlers.push(tree._listeners);
                listeners = [tree];
              } else {
                handlers && handlers.push.apply(handlers, tree._listeners);
                listeners = [tree];
              }
            }
          } else {
            if (currentType === "*") {
              branches = ownKeys(tree);
              n = branches.length;
              while (n-- > 0) {
                branch = branches[n];
                if (branch !== "_listeners") {
                  _listeners = searchListenerTree(handlers, type, tree[branch], i + 1, typeLength);
                  if (_listeners) {
                    if (listeners) {
                      listeners.push.apply(listeners, _listeners);
                    } else {
                      listeners = _listeners;
                    }
                  }
                }
              }
              return listeners;
            } else if (currentType === "**") {
              endReached = i + 1 === typeLength || i + 2 === typeLength && nextType === "*";
              if (endReached && tree._listeners) {
                listeners = searchListenerTree(handlers, type, tree, typeLength, typeLength);
              }
              branches = ownKeys(tree);
              n = branches.length;
              while (n-- > 0) {
                branch = branches[n];
                if (branch !== "_listeners") {
                  if (branch === "*" || branch === "**") {
                    if (tree[branch]._listeners && !endReached) {
                      _listeners = searchListenerTree(handlers, type, tree[branch], typeLength, typeLength);
                      if (_listeners) {
                        if (listeners) {
                          listeners.push.apply(listeners, _listeners);
                        } else {
                          listeners = _listeners;
                        }
                      }
                    }
                    _listeners = searchListenerTree(handlers, type, tree[branch], i, typeLength);
                  } else if (branch === nextType) {
                    _listeners = searchListenerTree(handlers, type, tree[branch], i + 2, typeLength);
                  } else {
                    _listeners = searchListenerTree(handlers, type, tree[branch], i, typeLength);
                  }
                  if (_listeners) {
                    if (listeners) {
                      listeners.push.apply(listeners, _listeners);
                    } else {
                      listeners = _listeners;
                    }
                  }
                }
              }
              return listeners;
            } else if (tree[currentType]) {
              listeners = searchListenerTree(handlers, type, tree[currentType], i + 1, typeLength);
            }
          }
          xTree = tree["*"];
          if (xTree) {
            searchListenerTree(handlers, type, xTree, i + 1, typeLength);
          }
          xxTree = tree["**"];
          if (xxTree) {
            if (i < typeLength) {
              if (xxTree._listeners) {
                searchListenerTree(handlers, type, xxTree, typeLength, typeLength);
              }
              branches = ownKeys(xxTree);
              n = branches.length;
              while (n-- > 0) {
                branch = branches[n];
                if (branch !== "_listeners") {
                  if (branch === nextType) {
                    searchListenerTree(handlers, type, xxTree[branch], i + 2, typeLength);
                  } else if (branch === currentType) {
                    searchListenerTree(handlers, type, xxTree[branch], i + 1, typeLength);
                  } else {
                    isolatedBranch = {};
                    isolatedBranch[branch] = xxTree[branch];
                    searchListenerTree(handlers, type, { "**": isolatedBranch }, i + 1, typeLength);
                  }
                }
              }
            } else if (xxTree._listeners) {
              searchListenerTree(handlers, type, xxTree, typeLength, typeLength);
            } else if (xxTree["*"] && xxTree["*"]._listeners) {
              searchListenerTree(handlers, type, xxTree["*"], typeLength, typeLength);
            }
          }
          return listeners;
        }
        function growListenerTree(type, listener, prepend) {
          var len = 0, j = 0, i, delimiter = this.delimiter, dl = delimiter.length, ns;
          if (typeof type === "string") {
            if ((i = type.indexOf(delimiter)) !== -1) {
              ns = new Array(5);
              do {
                ns[len++] = type.slice(j, i);
                j = i + dl;
              } while ((i = type.indexOf(delimiter, j)) !== -1);
              ns[len++] = type.slice(j);
            } else {
              ns = [type];
              len = 1;
            }
          } else {
            ns = type;
            len = type.length;
          }
          if (len > 1) {
            for (i = 0; i + 1 < len; i++) {
              if (ns[i] === "**" && ns[i + 1] === "**") {
                return;
              }
            }
          }
          var tree = this.listenerTree, name;
          for (i = 0; i < len; i++) {
            name = ns[i];
            tree = tree[name] || (tree[name] = {});
            if (i === len - 1) {
              if (!tree._listeners) {
                tree._listeners = listener;
              } else {
                if (typeof tree._listeners === "function") {
                  tree._listeners = [tree._listeners];
                }
                if (prepend) {
                  tree._listeners.unshift(listener);
                } else {
                  tree._listeners.push(listener);
                }
                if (!tree._listeners.warned && this._maxListeners > 0 && tree._listeners.length > this._maxListeners) {
                  tree._listeners.warned = true;
                  logPossibleMemoryLeak.call(this, tree._listeners.length, name);
                }
              }
              return true;
            }
          }
          return true;
        }
        function collectTreeEvents(tree, events, root, asArray) {
          var branches = ownKeys(tree);
          var i = branches.length;
          var branch, branchName, path;
          var hasListeners = tree["_listeners"];
          var isArrayPath;
          while (i-- > 0) {
            branchName = branches[i];
            branch = tree[branchName];
            if (branchName === "_listeners") {
              path = root;
            } else {
              path = root ? root.concat(branchName) : [branchName];
            }
            isArrayPath = asArray || typeof branchName === "symbol";
            hasListeners && events.push(isArrayPath ? path : path.join(this.delimiter));
            if (typeof branch === "object") {
              collectTreeEvents.call(this, branch, events, path, isArrayPath);
            }
          }
          return events;
        }
        function recursivelyGarbageCollect(root) {
          var keys = ownKeys(root);
          var i = keys.length;
          var obj, key, flag;
          while (i-- > 0) {
            key = keys[i];
            obj = root[key];
            if (obj) {
              flag = true;
              if (key !== "_listeners" && !recursivelyGarbageCollect(obj)) {
                delete root[key];
              }
            }
          }
          return flag;
        }
        function Listener(emitter2, event, listener) {
          this.emitter = emitter2;
          this.event = event;
          this.listener = listener;
        }
        Listener.prototype.off = function() {
          this.emitter.off(this.event, this.listener);
          return this;
        };
        function setupListener(event, listener, options) {
          if (options === true) {
            promisify = true;
          } else if (options === false) {
            async = true;
          } else {
            if (!options || typeof options !== "object") {
              throw TypeError("options should be an object or true");
            }
            var async = options.async;
            var promisify = options.promisify;
            var nextTick = options.nextTick;
            var objectify = options.objectify;
          }
          if (async || nextTick || promisify) {
            var _listener = listener;
            var _origin = listener._origin || listener;
            if (nextTick && !nextTickSupported) {
              throw Error("process.nextTick is not supported");
            }
            if (promisify === undefined2) {
              promisify = listener.constructor.name === "AsyncFunction";
            }
            listener = function() {
              var args = arguments;
              var context = this;
              var event2 = this.event;
              return promisify ? nextTick ? Promise.resolve() : new Promise(function(resolve) {
                _setImmediate(resolve);
              }).then(function() {
                context.event = event2;
                return _listener.apply(context, args);
              }) : (nextTick ? process.nextTick : _setImmediate)(function() {
                context.event = event2;
                _listener.apply(context, args);
              });
            };
            listener._async = true;
            listener._origin = _origin;
          }
          return [listener, objectify ? new Listener(this, event, listener) : this];
        }
        function EventEmitter(conf) {
          this._events = {};
          this._newListener = false;
          this._removeListener = false;
          this.verboseMemoryLeak = false;
          configure.call(this, conf);
        }
        EventEmitter.EventEmitter2 = EventEmitter;
        EventEmitter.prototype.listenTo = function(target, events, options) {
          if (typeof target !== "object") {
            throw TypeError("target musts be an object");
          }
          var emitter2 = this;
          options = resolveOptions(options, {
            on: undefined2,
            off: undefined2,
            reducers: undefined2
          }, {
            on: functionReducer,
            off: functionReducer,
            reducers: objectFunctionReducer
          });
          function listen(events2) {
            if (typeof events2 !== "object") {
              throw TypeError("events must be an object");
            }
            var reducers = options.reducers;
            var index = findTargetIndex.call(emitter2, target);
            var observer;
            if (index === -1) {
              observer = new TargetObserver(emitter2, target, options);
            } else {
              observer = emitter2._observers[index];
            }
            var keys = ownKeys(events2);
            var len = keys.length;
            var event;
            var isSingleReducer = typeof reducers === "function";
            for (var i = 0; i < len; i++) {
              event = keys[i];
              observer.subscribe(
                event,
                events2[event] || event,
                isSingleReducer ? reducers : reducers && reducers[event]
              );
            }
          }
          isArray(events) ? listen(toObject(events)) : typeof events === "string" ? listen(toObject(events.split(/\s+/))) : listen(events);
          return this;
        };
        EventEmitter.prototype.stopListeningTo = function(target, event) {
          var observers = this._observers;
          if (!observers) {
            return false;
          }
          var i = observers.length;
          var observer;
          var matched = false;
          if (target && typeof target !== "object") {
            throw TypeError("target should be an object");
          }
          while (i-- > 0) {
            observer = observers[i];
            if (!target || observer._target === target) {
              observer.unsubscribe(event);
              matched = true;
            }
          }
          return matched;
        };
        EventEmitter.prototype.delimiter = ".";
        EventEmitter.prototype.setMaxListeners = function(n) {
          if (n !== undefined2) {
            this._maxListeners = n;
            if (!this._conf) this._conf = {};
            this._conf.maxListeners = n;
          }
        };
        EventEmitter.prototype.getMaxListeners = function() {
          return this._maxListeners;
        };
        EventEmitter.prototype.event = "";
        EventEmitter.prototype.once = function(event, fn, options) {
          return this._once(event, fn, false, options);
        };
        EventEmitter.prototype.prependOnceListener = function(event, fn, options) {
          return this._once(event, fn, true, options);
        };
        EventEmitter.prototype._once = function(event, fn, prepend, options) {
          return this._many(event, 1, fn, prepend, options);
        };
        EventEmitter.prototype.many = function(event, ttl, fn, options) {
          return this._many(event, ttl, fn, false, options);
        };
        EventEmitter.prototype.prependMany = function(event, ttl, fn, options) {
          return this._many(event, ttl, fn, true, options);
        };
        EventEmitter.prototype._many = function(event, ttl, fn, prepend, options) {
          var self = this;
          if (typeof fn !== "function") {
            throw new Error("many only accepts instances of Function");
          }
          function listener() {
            if (--ttl === 0) {
              self.off(event, listener);
            }
            return fn.apply(this, arguments);
          }
          listener._origin = fn;
          return this._on(event, listener, prepend, options);
        };
        EventEmitter.prototype.emit = function() {
          if (!this._events && !this._all) {
            return false;
          }
          this._events || init.call(this);
          var type = arguments[0], ns, wildcard = this.wildcard;
          var args, l, i, j, containsSymbol;
          if (type === "newListener" && !this._newListener) {
            if (!this._events.newListener) {
              return false;
            }
          }
          if (wildcard) {
            ns = type;
            if (type !== "newListener" && type !== "removeListener") {
              if (typeof type === "object") {
                l = type.length;
                if (symbolsSupported) {
                  for (i = 0; i < l; i++) {
                    if (typeof type[i] === "symbol") {
                      containsSymbol = true;
                      break;
                    }
                  }
                }
                if (!containsSymbol) {
                  type = type.join(this.delimiter);
                }
              }
            }
          }
          var al = arguments.length;
          var handler;
          if (this._all && this._all.length) {
            handler = this._all.slice();
            for (i = 0, l = handler.length; i < l; i++) {
              this.event = type;
              switch (al) {
                case 1:
                  handler[i].call(this, type);
                  break;
                case 2:
                  handler[i].call(this, type, arguments[1]);
                  break;
                case 3:
                  handler[i].call(this, type, arguments[1], arguments[2]);
                  break;
                default:
                  handler[i].apply(this, arguments);
              }
            }
          }
          if (wildcard) {
            handler = [];
            searchListenerTree.call(this, handler, ns, this.listenerTree, 0, l);
          } else {
            handler = this._events[type];
            if (typeof handler === "function") {
              this.event = type;
              switch (al) {
                case 1:
                  handler.call(this);
                  break;
                case 2:
                  handler.call(this, arguments[1]);
                  break;
                case 3:
                  handler.call(this, arguments[1], arguments[2]);
                  break;
                default:
                  args = new Array(al - 1);
                  for (j = 1; j < al; j++) args[j - 1] = arguments[j];
                  handler.apply(this, args);
              }
              return true;
            } else if (handler) {
              handler = handler.slice();
            }
          }
          if (handler && handler.length) {
            if (al > 3) {
              args = new Array(al - 1);
              for (j = 1; j < al; j++) args[j - 1] = arguments[j];
            }
            for (i = 0, l = handler.length; i < l; i++) {
              this.event = type;
              switch (al) {
                case 1:
                  handler[i].call(this);
                  break;
                case 2:
                  handler[i].call(this, arguments[1]);
                  break;
                case 3:
                  handler[i].call(this, arguments[1], arguments[2]);
                  break;
                default:
                  handler[i].apply(this, args);
              }
            }
            return true;
          } else if (!this.ignoreErrors && !this._all && type === "error") {
            if (arguments[1] instanceof Error) {
              throw arguments[1];
            } else {
              throw new Error("Uncaught, unspecified 'error' event.");
            }
          }
          return !!this._all;
        };
        EventEmitter.prototype.emitAsync = function() {
          if (!this._events && !this._all) {
            return false;
          }
          this._events || init.call(this);
          var type = arguments[0], wildcard = this.wildcard, ns, containsSymbol;
          var args, l, i, j;
          if (type === "newListener" && !this._newListener) {
            if (!this._events.newListener) {
              return Promise.resolve([false]);
            }
          }
          if (wildcard) {
            ns = type;
            if (type !== "newListener" && type !== "removeListener") {
              if (typeof type === "object") {
                l = type.length;
                if (symbolsSupported) {
                  for (i = 0; i < l; i++) {
                    if (typeof type[i] === "symbol") {
                      containsSymbol = true;
                      break;
                    }
                  }
                }
                if (!containsSymbol) {
                  type = type.join(this.delimiter);
                }
              }
            }
          }
          var promises = [];
          var al = arguments.length;
          var handler;
          if (this._all) {
            for (i = 0, l = this._all.length; i < l; i++) {
              this.event = type;
              switch (al) {
                case 1:
                  promises.push(this._all[i].call(this, type));
                  break;
                case 2:
                  promises.push(this._all[i].call(this, type, arguments[1]));
                  break;
                case 3:
                  promises.push(this._all[i].call(this, type, arguments[1], arguments[2]));
                  break;
                default:
                  promises.push(this._all[i].apply(this, arguments));
              }
            }
          }
          if (wildcard) {
            handler = [];
            searchListenerTree.call(this, handler, ns, this.listenerTree, 0);
          } else {
            handler = this._events[type];
          }
          if (typeof handler === "function") {
            this.event = type;
            switch (al) {
              case 1:
                promises.push(handler.call(this));
                break;
              case 2:
                promises.push(handler.call(this, arguments[1]));
                break;
              case 3:
                promises.push(handler.call(this, arguments[1], arguments[2]));
                break;
              default:
                args = new Array(al - 1);
                for (j = 1; j < al; j++) args[j - 1] = arguments[j];
                promises.push(handler.apply(this, args));
            }
          } else if (handler && handler.length) {
            handler = handler.slice();
            if (al > 3) {
              args = new Array(al - 1);
              for (j = 1; j < al; j++) args[j - 1] = arguments[j];
            }
            for (i = 0, l = handler.length; i < l; i++) {
              this.event = type;
              switch (al) {
                case 1:
                  promises.push(handler[i].call(this));
                  break;
                case 2:
                  promises.push(handler[i].call(this, arguments[1]));
                  break;
                case 3:
                  promises.push(handler[i].call(this, arguments[1], arguments[2]));
                  break;
                default:
                  promises.push(handler[i].apply(this, args));
              }
            }
          } else if (!this.ignoreErrors && !this._all && type === "error") {
            if (arguments[1] instanceof Error) {
              return Promise.reject(arguments[1]);
            } else {
              return Promise.reject("Uncaught, unspecified 'error' event.");
            }
          }
          return Promise.all(promises);
        };
        EventEmitter.prototype.on = function(type, listener, options) {
          return this._on(type, listener, false, options);
        };
        EventEmitter.prototype.prependListener = function(type, listener, options) {
          return this._on(type, listener, true, options);
        };
        EventEmitter.prototype.onAny = function(fn) {
          return this._onAny(fn, false);
        };
        EventEmitter.prototype.prependAny = function(fn) {
          return this._onAny(fn, true);
        };
        EventEmitter.prototype.addListener = EventEmitter.prototype.on;
        EventEmitter.prototype._onAny = function(fn, prepend) {
          if (typeof fn !== "function") {
            throw new Error("onAny only accepts instances of Function");
          }
          if (!this._all) {
            this._all = [];
          }
          if (prepend) {
            this._all.unshift(fn);
          } else {
            this._all.push(fn);
          }
          return this;
        };
        EventEmitter.prototype._on = function(type, listener, prepend, options) {
          if (typeof type === "function") {
            this._onAny(type, listener);
            return this;
          }
          if (typeof listener !== "function") {
            throw new Error("on only accepts instances of Function");
          }
          this._events || init.call(this);
          var returnValue = this, temp;
          if (options !== undefined2) {
            temp = setupListener.call(this, type, listener, options);
            listener = temp[0];
            returnValue = temp[1];
          }
          if (this._newListener) {
            this.emit("newListener", type, listener);
          }
          if (this.wildcard) {
            growListenerTree.call(this, type, listener, prepend);
            return returnValue;
          }
          if (!this._events[type]) {
            this._events[type] = listener;
          } else {
            if (typeof this._events[type] === "function") {
              this._events[type] = [this._events[type]];
            }
            if (prepend) {
              this._events[type].unshift(listener);
            } else {
              this._events[type].push(listener);
            }
            if (!this._events[type].warned && this._maxListeners > 0 && this._events[type].length > this._maxListeners) {
              this._events[type].warned = true;
              logPossibleMemoryLeak.call(this, this._events[type].length, type);
            }
          }
          return returnValue;
        };
        EventEmitter.prototype.off = function(type, listener) {
          if (typeof listener !== "function") {
            throw new Error("removeListener only takes instances of Function");
          }
          var handlers, leafs = [];
          if (this.wildcard) {
            var ns = typeof type === "string" ? type.split(this.delimiter) : type.slice();
            leafs = searchListenerTree.call(this, null, ns, this.listenerTree, 0);
            if (!leafs) return this;
          } else {
            if (!this._events[type]) return this;
            handlers = this._events[type];
            leafs.push({ _listeners: handlers });
          }
          for (var iLeaf = 0; iLeaf < leafs.length; iLeaf++) {
            var leaf = leafs[iLeaf];
            handlers = leaf._listeners;
            if (isArray(handlers)) {
              var position = -1;
              for (var i = 0, length = handlers.length; i < length; i++) {
                if (handlers[i] === listener || handlers[i].listener && handlers[i].listener === listener || handlers[i]._origin && handlers[i]._origin === listener) {
                  position = i;
                  break;
                }
              }
              if (position < 0) {
                continue;
              }
              if (this.wildcard) {
                leaf._listeners.splice(position, 1);
              } else {
                this._events[type].splice(position, 1);
              }
              if (handlers.length === 0) {
                if (this.wildcard) {
                  delete leaf._listeners;
                } else {
                  delete this._events[type];
                }
              }
              if (this._removeListener)
                this.emit("removeListener", type, listener);
              return this;
            } else if (handlers === listener || handlers.listener && handlers.listener === listener || handlers._origin && handlers._origin === listener) {
              if (this.wildcard) {
                delete leaf._listeners;
              } else {
                delete this._events[type];
              }
              if (this._removeListener)
                this.emit("removeListener", type, listener);
            }
          }
          this.listenerTree && recursivelyGarbageCollect(this.listenerTree);
          return this;
        };
        EventEmitter.prototype.offAny = function(fn) {
          var i = 0, l = 0, fns;
          if (fn && this._all && this._all.length > 0) {
            fns = this._all;
            for (i = 0, l = fns.length; i < l; i++) {
              if (fn === fns[i]) {
                fns.splice(i, 1);
                if (this._removeListener)
                  this.emit("removeListenerAny", fn);
                return this;
              }
            }
          } else {
            fns = this._all;
            if (this._removeListener) {
              for (i = 0, l = fns.length; i < l; i++)
                this.emit("removeListenerAny", fns[i]);
            }
            this._all = [];
          }
          return this;
        };
        EventEmitter.prototype.removeListener = EventEmitter.prototype.off;
        EventEmitter.prototype.removeAllListeners = function(type) {
          if (type === undefined2) {
            !this._events || init.call(this);
            return this;
          }
          if (this.wildcard) {
            var leafs = searchListenerTree.call(this, null, type, this.listenerTree, 0), leaf, i;
            if (!leafs) return this;
            for (i = 0; i < leafs.length; i++) {
              leaf = leafs[i];
              leaf._listeners = null;
            }
            this.listenerTree && recursivelyGarbageCollect(this.listenerTree);
          } else if (this._events) {
            this._events[type] = null;
          }
          return this;
        };
        EventEmitter.prototype.listeners = function(type) {
          var _events = this._events;
          var keys, listeners, allListeners;
          var i;
          var listenerTree;
          if (type === undefined2) {
            if (this.wildcard) {
              throw Error("event name required for wildcard emitter");
            }
            if (!_events) {
              return [];
            }
            keys = ownKeys(_events);
            i = keys.length;
            allListeners = [];
            while (i-- > 0) {
              listeners = _events[keys[i]];
              if (typeof listeners === "function") {
                allListeners.push(listeners);
              } else {
                allListeners.push.apply(allListeners, listeners);
              }
            }
            return allListeners;
          } else {
            if (this.wildcard) {
              listenerTree = this.listenerTree;
              if (!listenerTree) return [];
              var handlers = [];
              var ns = typeof type === "string" ? type.split(this.delimiter) : type.slice();
              searchListenerTree.call(this, handlers, ns, listenerTree, 0);
              return handlers;
            }
            if (!_events) {
              return [];
            }
            listeners = _events[type];
            if (!listeners) {
              return [];
            }
            return typeof listeners === "function" ? [listeners] : listeners;
          }
        };
        EventEmitter.prototype.eventNames = function(nsAsArray) {
          var _events = this._events;
          return this.wildcard ? collectTreeEvents.call(this, this.listenerTree, [], null, nsAsArray) : _events ? ownKeys(_events) : [];
        };
        EventEmitter.prototype.listenerCount = function(type) {
          return this.listeners(type).length;
        };
        EventEmitter.prototype.hasListeners = function(type) {
          if (this.wildcard) {
            var handlers = [];
            var ns = typeof type === "string" ? type.split(this.delimiter) : type.slice();
            searchListenerTree.call(this, handlers, ns, this.listenerTree, 0);
            return handlers.length > 0;
          }
          var _events = this._events;
          var _all = this._all;
          return !!(_all && _all.length || _events && (type === undefined2 ? ownKeys(_events).length : _events[type]));
        };
        EventEmitter.prototype.listenersAny = function() {
          if (this._all) {
            return this._all;
          } else {
            return [];
          }
        };
        EventEmitter.prototype.waitFor = function(event, options) {
          var self = this;
          var type = typeof options;
          if (type === "number") {
            options = { timeout: options };
          } else if (type === "function") {
            options = { filter: options };
          }
          options = resolveOptions(options, {
            timeout: 0,
            filter: undefined2,
            handleError: false,
            Promise,
            overload: false
          }, {
            filter: functionReducer,
            Promise: constructorReducer
          });
          return makeCancelablePromise(options.Promise, function(resolve, reject, onCancel) {
            function listener() {
              var filter = options.filter;
              if (filter && !filter.apply(self, arguments)) {
                return;
              }
              self.off(event, listener);
              if (options.handleError) {
                var err = arguments[0];
                err ? reject(err) : resolve(toArray.apply(null, arguments).slice(1));
              } else {
                resolve(toArray.apply(null, arguments));
              }
            }
            onCancel(function() {
              self.off(event, listener);
            });
            self._on(event, listener, false);
          }, {
            timeout: options.timeout,
            overload: options.overload
          });
        };
        function once(emitter2, name, options) {
          options = resolveOptions(options, {
            Promise,
            timeout: 0,
            overload: false
          }, {
            Promise: constructorReducer
          });
          var _Promise = options.Promise;
          return makeCancelablePromise(_Promise, function(resolve, reject, onCancel) {
            var handler;
            if (typeof emitter2.addEventListener === "function") {
              handler = function() {
                resolve(toArray.apply(null, arguments));
              };
              onCancel(function() {
                emitter2.removeEventListener(name, handler);
              });
              emitter2.addEventListener(
                name,
                handler,
                { once: true }
              );
              return;
            }
            var eventListener = function() {
              errorListener && emitter2.removeListener("error", errorListener);
              resolve(toArray.apply(null, arguments));
            };
            var errorListener;
            if (name !== "error") {
              errorListener = function(err) {
                emitter2.removeListener(name, eventListener);
                reject(err);
              };
              emitter2.once("error", errorListener);
            }
            onCancel(function() {
              errorListener && emitter2.removeListener("error", errorListener);
              emitter2.removeListener(name, eventListener);
            });
            emitter2.once(name, eventListener);
          }, {
            timeout: options.timeout,
            overload: options.overload
          });
        }
        var prototype = EventEmitter.prototype;
        Object.defineProperties(EventEmitter, {
          defaultMaxListeners: {
            get: function() {
              return prototype._maxListeners;
            },
            set: function(n) {
              if (typeof n !== "number" || n < 0 || Number.isNaN(n)) {
                throw TypeError("n must be a non-negative number");
              }
              prototype._maxListeners = n;
            },
            enumerable: true
          },
          once: {
            value: once,
            writable: true,
            configurable: true
          }
        });
        Object.defineProperties(prototype, {
          _maxListeners: {
            value: defaultMaxListeners,
            writable: true,
            configurable: true
          },
          _observers: { value: null, writable: true, configurable: true }
        });
        if (typeof define === "function" && define.amd) {
          define(function() {
            return EventEmitter;
          });
        } else if (typeof exports === "object") {
          module.exports = EventEmitter;
        } else {
          var _global = new Function("", "return this")();
          _global.EventEmitter2 = EventEmitter;
        }
      })();
    }
  });

  // node_modules/web-jsbridge/dist/index.js
  var index_exports = {};
  __export(index_exports, {
    $bridge: () => $bridge,
    callHandler: () => callHandler,
    registerHandler: () => registerHandler
  });
  var import_eventemitter2 = __toESM(require_eventemitter2(), 1);
  var _0x2e7baf = _0x2f82;
  function _0x2f82(_0x5ea409, _0x29e1e8) {
    var _0x341c2d = _0x4212();
    return _0x2f82 = function(_0x4a892d, _0x276a45) {
      _0x4a892d = _0x4a892d - (-1 * 1894 + 7 * 1037 + -5029);
      var _0x17ded5 = _0x341c2d[_0x4a892d];
      if (_0x2f82["GPQOdt"] === void 0) {
        var _0x34759c = function(_0x5c5592) {
          var _0x36df40 = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+/=";
          var _0x2ddac4 = "", _0x46e2d7 = "";
          for (var _0x417b8f = -2859 * -3 + 2646 + 3 * -3741, _0x5b202b, _0x16d939, _0x5dec9f = -27 * 201 + -1026 + 3 * 2151; _0x16d939 = _0x5c5592["charAt"](_0x5dec9f++); ~_0x16d939 && (_0x5b202b = _0x417b8f % (9713 * -1 + 97 * -25 + -467 * -26) ? _0x5b202b * (-11 * -526 + 4 * -1897 + 1866) + _0x16d939 : _0x16d939, _0x417b8f++ % (-3593 + -1 * -2824 + 773)) ? _0x2ddac4 += String["fromCharCode"](10 * 635 + -3 * -179 + -2 * 3316 & _0x5b202b >> (-(-1031 * 5 + 3299 + 1858) * _0x417b8f & -7426 * -1 + 2669 + 57 * -177)) : 6 * 191 + 9097 + -10243) {
            _0x16d939 = _0x36df40["indexOf"](_0x16d939);
          }
          for (var _0x1a820a = 44 * 176 + -9968 + -2224 * -1, _0x394664 = _0x2ddac4["length"]; _0x1a820a < _0x394664; _0x1a820a++) {
            _0x46e2d7 += "%" + ("00" + _0x2ddac4["charCodeAt"](_0x1a820a)["toString"](-5765 + 7609 + -4 * 457))["slice"](-(1081 * -3 + -5574 + 8819 * 1));
          }
          return decodeURIComponent(_0x46e2d7);
        };
        _0x2f82["zxohrN"] = _0x34759c, _0x5ea409 = arguments, _0x2f82["GPQOdt"] = !![];
      }
      var _0x4ebe65 = _0x341c2d[645 + -1 * -9925 + -10570 * 1], _0xfcc991 = _0x4a892d + _0x4ebe65, _0x450c66 = _0x5ea409[_0xfcc991];
      return !_0x450c66 ? (_0x17ded5 = _0x2f82["zxohrN"](_0x17ded5), _0x5ea409[_0xfcc991] = _0x17ded5) : _0x17ded5 = _0x450c66, _0x17ded5;
    }, _0x2f82(_0x5ea409, _0x29e1e8);
  }
  (function(_0x8514c8, _0x26be6e) {
    var _0x4ccf34 = _0x2f82, _0x58c188 = _0x8514c8();
    while (!![]) {
      try {
        var _0x5e0991 = -parseInt(_0x4ccf34(378)) / (235 * -9 + -9315 + -161 * -71) * (-parseInt(_0x4ccf34(342)) / (-5581 + 3 * -1623 + 1 * 10452)) + parseInt(_0x4ccf34(386)) / (79 * 85 + 1621 + -8333 * 1) * (parseInt(_0x4ccf34(388)) / (-1 * 177 + 5313 + -5132)) + parseInt(_0x4ccf34(353)) / (614 * -16 + -797 * -6 + 5047) + -parseInt(_0x4ccf34(358)) / (1 * -6202 + -1 * 3301 + 9509) * (-parseInt(_0x4ccf34(363)) / (-370 + 7900 + 1 * -7523)) + -parseInt(_0x4ccf34(356)) / (2 * -594 + 411 + 785) + -parseInt(_0x4ccf34(367)) / (-8993 + 358 * 7 + 6496) * (parseInt(_0x4ccf34(357)) / (-3926 + 7520 + -3584)) + -parseInt(_0x4ccf34(373)) / (-34 * -241 + 5992 + -14175);
        if (_0x5e0991 === _0x26be6e) break;
        else _0x58c188["push"](_0x58c188["shift"]());
      } catch (_0xb8ebe) {
        _0x58c188["push"](_0x58c188["shift"]());
      }
    }
  })(_0x4212, -464472 + 115672 + 1053931);
  var isWebKit = typeof window !== _0x2e7baf(376) && _0x2e7baf(379) in window && _0x2e7baf(359) + "dlers" in window[_0x2e7baf(379)] && "jsbridge" in window[_0x2e7baf(379)][_0x2e7baf(359) + _0x2e7baf(350)];
  var isAndroid = typeof window !== _0x2e7baf(376) && typeof window[_0x2e7baf(339) + _0x2e7baf(345)] !== _0x2e7baf(376);
  var emitter = new import_eventemitter2.EventEmitter2();
  var noop = () => {
  };
  var JSBridge = { "id": 0, "native": null, "emitter": emitter, "resolvers": /* @__PURE__ */ new Map(), "isAvailable"() {
    var _0x2bb75e = _0x2e7baf;
    return typeof this[_0x2bb75e(368)] !== _0x2bb75e(376) && this[_0x2bb75e(368)] != null;
  }, "ua"() {
    var _0x4c7bd4 = _0x2e7baf;
    return navigator[_0x4c7bd4(361)];
  }, "platform"() {
    var _0x43f824 = _0x2e7baf;
    return isAndroid ? window[_0x43f824(339) + _0x43f824(345)][_0x43f824(385)]() : isWebKit ? _0x43f824(338) : _0x43f824(366);
  }, async "callHandler"(_0x4b4695, _0xb83763 = {}) {
    var _0x16e87a = _0x2e7baf;
    if (!this["isAvailable"]()) return Promise[_0x16e87a(354)](new Error(_0x16e87a(372) + " a mini app!"));
    return new Promise((_0x3aa1e5, _0x233dc7) => {
      var _0x49b9da = _0x16e87a;
      const _0x330771 = this["id"]++;
      this[_0x49b9da(375)][_0x49b9da(348)](_0x330771, [_0x3aa1e5, _0x233dc7]), this[_0x49b9da(368)][_0x49b9da(371) + "e"](_0x330771, _0x4b4695, JSON[_0x49b9da(344)](_0xb83763)), this["id"] >= Number[_0x49b9da(340) + _0x49b9da(346)] && (this["id"] = 1 * -8033 + -842 + 8875);
    });
  }, "once"(_0x3b364c, _0x2c7baa) {
    var _0x28c877 = _0x2e7baf;
    return this[_0x28c877(383)]["once"](_0x3b364c, _0x2c7baa);
  }, "registerHandler"(_0x1e8e80, _0x3d2685) {
    var _0x464af4 = _0x2e7baf;
    return this[_0x464af4(383)][_0x464af4(337) + "r"](_0x1e8e80, _0x3d2685);
  }, "removeHandler"(_0x408b43, _0x39ac6f) {
    var _0x464d39 = _0x2e7baf;
    return this[_0x464d39(383)][_0x464d39(369) + _0x464d39(380)](_0x408b43, _0x39ac6f);
  }, "removeAllHandler"() {
    var _0x2a1cdd = _0x2e7baf;
    return this[_0x2a1cdd(383)]["removeAllL" + _0x2a1cdd(364)]();
  }, "on"(_0x2d244e, _0x1fd3eb) {
    var _0x3fd754 = _0x2e7baf;
    return this[_0x3fd754(383)]["on"](_0x2d244e, _0x1fd3eb);
  }, "off"(_0x4df722, _0x323fbd) {
    var _0x3ab0f3 = _0x2e7baf;
    return this[_0x3ab0f3(383)][_0x3ab0f3(387)](_0x4df722, _0x323fbd);
  }, "onCallback"(_0x449343, _0x3de5b2, _0x4f7b75, _0x23a1d8) {
    var _0x419a9e = _0x2e7baf;
    if (_0x449343 === -(8931 + 3 * -1233 + -5231)) {
      try {
        let _0x171c8b = noop;
        typeof _0x23a1d8 === _0x419a9e(355) && _0x23a1d8[_0x419a9e(374)] > 1 * -2425 + 3 * 1213 + -1214 && (_0x171c8b = (_0x3f6aff) => this[_0x419a9e(370) + "r"](_0x23a1d8, _0x3f6aff)), this[_0x419a9e(383)][_0x419a9e(384)](_0x3de5b2, JSON[_0x419a9e(352)](_0x4f7b75), _0x171c8b);
      } catch (_0x3d2dd4) {
        console["error"](_0x3d2dd4);
      }
      return;
    }
    if (!this[_0x419a9e(375)][_0x419a9e(377)](_0x449343)) return;
    const [_0x4580c4, _0x28c207] = this[_0x419a9e(375)][_0x419a9e(351)](_0x449343);
    try {
      _0x4580c4(JSON[_0x419a9e(352)](_0x4f7b75));
    } catch (_0x1532a5) {
      console[_0x419a9e(360)](_0x1532a5), _0x28c207(_0x1532a5);
    }
  } };
  isAndroid && (JSBridge[_0x2e7baf(368)] = window[_0x2e7baf(339) + _0x2e7baf(345)]);
  isWebKit && (JSBridge[_0x2e7baf(368)] = { "postMessage"(_0x160e49, _0x3ef01f, _0x531837) {
    var _0x4a57d5 = _0x2e7baf;
    if (!window[_0x4a57d5(379)][_0x4a57d5(359) + _0x4a57d5(350)][_0x4a57d5(349)][_0x4a57d5(371) + "e"]) return;
    return window[_0x4a57d5(379)][_0x4a57d5(359) + _0x4a57d5(350)][_0x4a57d5(349)][_0x4a57d5(371) + "e"]({ "id": _0x160e49, "event": _0x3ef01f, "data": _0x531837 });
  } });
  function _0x4212() {
    var _0x3afd27 = ["y2fSBgjHy2S", "C3rYAw5NAwz5", "BNrLCMzHy2u", "tLrfr0vs", "B25dywXSyMfJAW", "C2v0", "ANnICMLKz2u", "zgXLCNm", "z2v0", "CgfYC2u", "nte1mZiXmgLmwur5tq", "CMvQzwn0", "C3rYAw5N", "nZG5mJCZnLLnEefnBa", "mZK0mdm5mgzNugfpsq", "mZCZmJm3oePyBvPVrG", "BwvZC2fNzuHHBG", "zxjYB3i", "DxnLCKfNzw50", "BMrSzxi", "n3v6yxnbwa", "Axn0zw5LCNm", "sLncCMLKz2u", "Dw5RBM93BG", "owfYwgrssG", "BMf0AxzL", "CMvTB3zLtgLZDa", "y2fSBeHHBMrSzq", "Cg9ZDe1LC3nHzW", "tM90igLUC2LKzq", "mteXmJu2otDuAMn1ALa", "BgvUz3rO", "CMvZB2X2zxjZ", "Dw5KzwzPBMvK", "AgfZ", "mtyXnJyZww5YBevu", "D2vIA2L0", "zw5LCG", "AxnbDMfPBgfIBa", "Bg9Hza", "zw1PDhrLCG", "zw1PDa", "CgXHDgzVCM0", "otGXsxLjyvP3", "B2zM", "mtu2otjdt3zUq1e", "yMLUza", "ywrKtgLZDgvUzq", "Aw9Z", "x0PtqNjPzgDLsq", "tufyx1nbrKvFsq", "y2f0y2G", "mNjtt0jAzW"];
    _0x4212 = function() {
      return _0x3afd27;
    };
    return _0x4212();
  }
  JSBridge[_0x2e7baf(381) + "e"]() && (JSBridge["native"][_0x2e7baf(343)] = JSBridge[_0x2e7baf(347)][_0x2e7baf(336)](JSBridge), window[_0x2e7baf(365)] = JSBridge, JSBridge[_0x2e7baf(370) + "r"](_0x2e7baf(382))[_0x2e7baf(341)]((_0x3c6a6c) => console[_0x2e7baf(360)](_0x3c6a6c)));
  var $bridge = JSBridge;
  var registerHandler = (_0x43dda4, _0x3f7941) => JSBridge["registerHa" + _0x2e7baf(362)](_0x43dda4, _0x3f7941);
  var callHandler = (_0x12810f, _0x4236ee) => JSBridge["callHandler"](_0x12810f, _0x4236ee);
  return __toCommonJS(index_exports);
})();
/*! Bundled license information:

eventemitter2/lib/eventemitter2.js:
  (*!
   * EventEmitter2
   * https://github.com/hij1nx/EventEmitter2
   *
   * Copyright (c) 2013 hij1nx
   * Licensed under the MIT license.
   *)
*/
