// Generated by CoffeeScript 1.6.3
/*
    init
*/

var CONFIG, Debugger, jQueryLoadModule, tools;

(function() {
  var $win, asyncLoad, asyncLoadTrigger, modules;
  modules = $('.async-module');
  $win = $(window);
  asyncLoad = function(preDistance) {
    var index, obj, _i, _len, _obj;
    if (preDistance == null) {
      preDistance = 0;
    }
    for (index = _i = 0, _len = modules.length; _i < _len; index = ++_i) {
      _obj = modules[index];
      obj = modules.eq(index);
      if (obj.offset().top < ($win.scrollTop() + $win.height() + preDistance)) {
        obj.loadModule();
        if (index === modules.length - 1) {
          modules = modules.slice(index + 1);
        }
      } else {
        if (index > 0) {
          modules = modules.slice(index);
        }
        break;
      }
    }
    if (modules.length === 0) {
      $win.off('scroll', asyncLoadTrigger);
    }
  };
  asyncLoadTrigger = function() {
    clearTimeout(arguments.callee.tid);
    return arguments.callee.tid = setTimeout(function() {
      return asyncLoad(CONFIG.bufferHeight || $win.height() / 2);
    }, 50);
  };
  if (modules.length > 0) {
    $win.on('scroll', asyncLoadTrigger);
    return asyncLoadTrigger();
  }
})();

tools = {
  getAttribute: function(domString) {
    var regDOMAttr, ret;
    ret = {};
    domString = domString.replace(/,\s*/g, ",");
    regDOMAttr = /([\w]*)[\s]*=[\s]*([\w\/._,]*)/g;
    domString.replace(regDOMAttr, function(match, p1, p2) {
      return ret[p1] = p2;
    });
    return ret;
  },
  regJS: /<script([^>]*)>([\w\W]*?)<\/script>/g,
  filterJS: function(str) {
    var matched, remain;
    matched = "";
    remain = str.replace(this.regJS, function(match, p1, p2, offset, origin) {
      matched += p2;
      return "";
    });
    return {
      remain: remain,
      matched: matched
    };
  },
  exec: function(JSStr, parent) {
    return (new Function(JSStr)).call(parent);
  },
  _prepareHTML: function(str) {
    var JSStripped, dom;
    JSStripped = this.filterJS(str);
    return dom = {
      js: JSStripped.matched,
      dom: JSStripped.remain
    };
  },
  loadHtml: function(str, parent) {
    var html;
    html = this._prepareHTML(str);
    if (html.dom) {
      if (html.dom.replace(/(^\s*)|(\s*$)/g, "").length > 0) {
        parent.html(html.dom);
      }
    }
    if (html.js) {
      return this.exec(html.js, parent);
    }
  },
  debug: function(target) {
    if (!CONFIG.DEBUG) {
      return;
    }
    Debugger.showInfo(target);
    target.css('padding', '1px');
    return target.css('background', 'red');
  }
};

CONFIG = {
  DEBUG: true
};

if (CONFIG.DEBUG === true) {
  CONFIG.bufferHeight = -100;
}

Debugger = {
  id: 0,
  showInfo: function(target) {
    var info, origin, source, time, type;
    type = target.data('type');
    origin = target.html();
    source = target.html().replace(/(^\s*)|(\s*$)/g, "").replace(/(<\!--)|(-->)/g, "");
    time = new Date();
    info = $("<div class='amd'>\n    <div class='title'>\n        ID: " + this.id + ", TYPE: <span class='em'>" + type + "</span><span class='time'>" + (time.toTimeString().slice(0, 9) + time.getMilliseconds()) + "</span>\n    </div>\n    <div>\n        <span><button onclick='showSourceCode(this)'>原始HTML</button><textarea>" + origin + "</textarea></span>\n        <span><button onclick='showSourceCode(this)'>解析出的代码</button><textarea>" + source + "</textarea></span>\n    </div>\n</div>");
    info.insertBefore(target);
    return this.id++;
  },
  init: (function() {
    if (!CONFIG.DEBUG) {
      return;
    }
    $("<style type='text/css'>\n  .amd {background: #CCE8CF}\n.amd .title{background: lightgreen}\n.amd .em {color: darkred; font-weight: bold}\n.amd textarea{display: none}\n.amd .time {float: right;}\n\n#amd-code {\n    position: fixed;\n    left: 0;\n    top: 0;\n    background: #CCE8CF;\n    width: 450px;\n    height: 100%;\n}\n  </style>").appendTo("head");
    return window.showSourceCode = function(self) {
      if (!self.show) {
        $("#amd-code").remove();
        self.show = true;
        return $("<textarea id='amd-code'>" + $(self).next().html() + "</textarea>").appendTo("body");
      } else {
        self.show = false;
        return $("#amd-code").remove();
      }
    };
  })()
};

jQueryLoadModule = function() {
  var e, origin, source, tmpl, type;
  try {
    type = this.data('type');
    switch (type) {
      case 'tmpl':
        tmpl = this.children();
        return this.html(tmpl.html());
      default:
        origin = this.html().replace(/(^\s*)|(\s*$)/g, "");
        if (origin.indexOf('<\!--') === -1) {
          return;
        }
        tools.debug(this);
        source = origin.replace(/(<\!--)|(-->)/g, "");
        return tools.loadHtml(source, this);
    }
  } catch (_error) {
    e = _error;
    if (console) {
      return console.log(e.stack);
    }
  }
};

$.fn.loadModule = jQueryLoadModule;
