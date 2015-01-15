#<script type="text/coffeescript" target="/home/wangyu/IdeaProjects/jch/new/src/static/jsx/plugins/async_module.js">


###
   music: /home/wangyu/IdeaProjects/jch/asyncVersion/src/common/async_module/jquery.asyncModule.js
   piao: /home/wangyu/IdeaProjects/piao/1227/src/static/js/widget/async_module.js
###

###
    configuration
###

CONFIG =
    DEBUG: true && location.search.indexOf('AD') isnt -1

DEBUG = CONFIG.DEBUG

if CONFIG.DEBUG is true
    CONFIG.bufferHeight =  -30


###
    add loadModule() as jquery plugin function
###
tools =
    getAttribute: (domString) ->
        ret = {}
        # convert "a, b" to "a,b" form
        domString = domString.replace(/,\s*/g, ",")

        # match " target =  'hello_world.js' "
        regDOMAttr = /([\w]*)[\s]*=[\s]*([\w\/._,]*)/g

        domString.replace(regDOMAttr, (match, p1, p2)->
            ret[p1] = p2
        )
        return ret
    regJS: /<script([^>]*)>([\w\W]*?)<\/script>/g
    filterJS: (str)->
        matched = ""
        remain = str.replace(this.regJS, (match, p1, p2, offset, origin)->
            # p2 - the content of script
            matched += p2
            # remove from str to generate pure dom string
            return ""
        )
        return {
            remain: remain
            matched: matched
        }

    exec: (JSStr, parent)->
        (new Function(JSStr)).call(parent)

    _prepareHTML: (str)->
        JSStripped = @filterJS(str)

        dom =
            js: JSStripped.matched
            dom: JSStripped.remain


    loadHtml: (str, parent)->
        # return parent.html(str)

        html = @_prepareHTML(str)
        if html.dom
            if html.dom.replace(/(^\s*)|(\s*$)/g, "").length > 0
                parent.html(html.dom)

#        (new Function(jsStr)).call(parent)
        if html.js
            @exec(html.js, parent)

    debug: (target)->
        return if !CONFIG.DEBUG

        Debugger.showInfo(target)

        target.css('padding', '1px')
        target.css('background', 'red')
    ###
        load html, css, js fragment through ajax
    ###
    loadAjaxData: ()->
        self = this
        url = self.data "url"
        return if not url
        $.ajax
            url: url
            dataType: "json"
        .done (retData)->
            self.html retData.data.html
            self.removeClass("css-loading")

            (new Function(retData.data.js)).call(self)
        .fail ()->
            self.html "<div class='async-module-error'><a href='#'>长时间没有响应，点击重新加载</a></div>"
            reload = self.find('.async-module-error')
            reload.css
                position: 'relative'
                top: self.height() / 2 + 20
                left: self.width() / 2 - 90
            reload.on 'click', (e)->
                e.preventDefault()
                tools.loadAjaxData.call(self, url)
                self.html ''

        return



###

###
util =
    reg_JS: /<script([^>]*)>([\w\W]*?)<\/script>/g
    # 匹配模块注释标记的正则
    reg_comment_wrapper: /(^<\!--)|(-->$)/g

###

    Class: AsyncDom (AsyncModule)

###
class AsyncDOM
    constructor: (@root, @domStr)->
        @load(root)

    ###
        提取出script标签中的内容
        @return {Object}
            -   remain 剩余的DOM
            -   matched 匹配到的标签中的内容
    ###
    filterJS: (str)->
        matched = ""
        remain = str.replace(util.reg_JS, (match, p1, p2, offset, origin)->
            # p2 - the content of script
            matched += p2
            # remove from str to generate pure dom string
            return ""
        )
        return {
            remain: remain
            matched: matched
        }
    ###
        execute script
    ###
    exec: (JSStr, parent)->
        (new Function(JSStr)).call(parent)

    _prepareHTML: (str)->
        JSStripped = @filterJS(str)

        return {
            js: JSStripped.matched
            dom: JSStripped.remain
        }


    load: (parent)->
        # out put debug info
        DEBUG and (_debug_time = [])

        # check if need async load by check the existance of '<\!--'
        origin = @domStr.replace(/(^\s*)|(\s*$)/g, "")


        # no need to aysnc load this since it's not wrapped by '<\!-- -->'
        return if origin.indexOf('<\!--') is -1

        DEBUG and _debug_time.push(new Date())

        # extract js && css, left html
        source = origin.replace(util.reg_comment_wrapper, "")

        html = @_prepareHTML(source)

        DEBUG and _debug_time.push(new Date())

        # insert dom
        if html.dom
            if html.dom.replace(/(^\s*)|(\s*$)/g, "").length > 0
                parent.html(html.dom)

        DEBUG and _debug_time.push(new Date())

        # execute script
        if html.js
            @exec(html.js, parent)
#            console.log("xx")
#            start = new Date()
#            i = 0
#            while (new Date() - start) < 5
#                i++
#            console.log(i)

        DEBUG and _debug_time.push(new Date())
        DEBUG and @debug(parent, html, _debug_time)

    debug: (root, html, render_timeline)->


        root.css("position", "relative");
        debugPanel = Debugger.genInfo(html, render_timeline)

        root.append(debugPanel)

        @observe(root, ()->
            root.append(debugPanel)
        )

    observe: (container, cb)->
        observer = new MutationObserver (mutations)->
            cb and cb()
            observer.disconnect()

        config =
            attributes: true
            childList: true
            characterData: true

        observer.observe container[0], config

#        observer.disconnect();

    ###

        用于显示调试信息

    ###
#    debug: (target)->
#        return if !CONFIG.DEBUG
#
#        Debugger.showInfo(target)
#
#        target.css('padding', '1px')
#        target.css('background', 'red')

Debugger =
    id: 0
    genInfo: (html, render_timeline)->
        time_interval_stack = []

        for item, i in render_timeline[0...render_timeline.length - 1]
            time_interval_stack[i] = render_timeline[i+1] - render_timeline[i]


        if html.dom
            debug_html_info = """<textarea rows="10">#{html.dom}</textarea>"""
        else
            debug_html_info = "——"

        return $("""
            <div class='amd'>
                <div class='title'>ID: #{@id++}</div>
                <div class='content'>
                    <div class='section'>渲染时间(ms)：
                        <div class='row'>解析DOM：#{time_interval_stack[0]}</div>
                        <div class='row'>DOM插入：#{time_interval_stack[1]}</div>
                        <div class='row'>JS执行：#{time_interval_stack[2] || 0}</div>
                    </div>

                    <div class="section">JS內容：
                        <div class="row">#{html.js || "无"}</div>
                    </div>
                </div>
            </div>
                 """)



    showInfo: (target)->
        type = target.data 'type'

        origin = target.html()
        source = target.html().replace(/(^\s*)|(\s*$)/g, "").replace(/(<\!--)|(-->)/g, "")

        time = new Date()

        info = $("""
        <div class='amd'>
            <div class='title'>
                ID: #{this.id}, TYPE: <span class='em'>#{type}</span><span class='time'>#{time.toTimeString().slice(0, 9) + time.getMilliseconds()}</span>
            </div>

            <div>
                <span><button onclick='showSourceCode(this)'>原始HTML</button><textarea>#{origin}</textarea></span>
                <span><button onclick='showSourceCode(this)'>解析出的代码</button><textarea>#{source}</textarea></span>
            </div>
        </div>
        """)

        info.insertBefore(target)

#        target.css('box-shadow', '0px 0px 1px 1px')


        @id++

    _init: do ()->
        return if !CONFIG.DEBUG
        $("""<style type='text/css'>
          .amd {background: #CCE8CF; position: absolute; z-index: 1314;top: 0;opacity: .9;width: 100%;height: 100%;left:0;}
          .amd.html{background: }
        .amd .title{background: lightgreen;}
        .amd .section .row{padding-left: 20px;}
        .amd .em {color: darkred; font-weight: bold}
        .amd textarea{width: 100%}
        .amd .time {float: right;}

        #amd-code {
            position: fixed;
            left: 0;
            top: 0;
            background: #CCE8CF;
            width: 450px;
            height: 100%;
        }
          </style>""").appendTo("head");


        window.showSourceCode = (self)->
            if !self.show
                $("#amd-code").remove();
                self.show = true
                $("<textarea id='amd-code'>" + $(self).next().html() + "</textarea>").appendTo("body")
            else
                self.show = false
                $("#amd-code").remove();

###
    declaration as jquery plugin method
###
$.fn.loadModule = jQueryLoadModule = ()->
    try
        type = this.data 'type'


        switch type
            when 'ajax'
                # out put debug info
                tools.debug(this);

                # load tmpl content in the script tag
                tools.loadAjaxData.call($(this))
            else
#                tools.loadHtml(source, this)
                new AsyncDOM(this, this.html());

    catch e
        if CONFIG.DEBUG then throw e

# exposed as jquery plugin
#$.fn.loadModule = jQueryLoadModule


###
    init auto load event
###
do ()->
    # create style for async-module
#    $("<style type='text/css'> .async-module{display: none} </style>").appendTo("head");

    modules = $ '.async-module'
    $win = $ window

    asyncLoad = (preDistance = 0)->
        DEBUG && (start = new Date())
        moduleCountToLoad = 0
        moduleCountLoaded = 0
        scrollTop = $win.scrollTop()
        winHeight = $win.height()
        for index in [0...modules.length] by 1
            #console.log "handle #{index}/#{modules.length}"
            obj = modules.eq(index)
            # 删除元素后，留下的是undefined，直接eq undefined 出来的jQuery 对象并不是undefined，而是obj[0]为undefined
            if obj[0] isnt undefined
                top = obj.offset().top

                if top < (scrollTop + winHeight + preDistance) && (scrollTop - preDistance - obj.height()) < top
                    #console.log "loadmodule #{obj.attr('data-load-module')}"
                    obj.loadModule()
                    delete modules[index]
                    moduleCountLoaded++
                else
                    moduleCountToLoad++

        DEBUG && moduleCountLoaded && (console.log "[Async Module]:#加载的模块数#{moduleCountLoaded}  # 执行时间: " + (new Date() - start) + "ms")
        DEBUG && (not moduleCountToLoad) && (console.log "[Async Module]:[DONE] 全部异步模块加载完成")

        if moduleCountToLoad is 0
            $win.off 'scroll', asyncLoadTrigger

        return


    asyncLoadTrigger = ()->
        clearTimeout arguments.callee.tid
        arguments.callee.tid = setTimeout ()->
            asyncLoad( CONFIG.bufferHeight or $win.height()/2 )
        , 50

    # init events
    if modules.length > 0
        $win.on 'scroll', asyncLoadTrigger
        # no need for register on window.onload event since this script is loading by requirejs
        # binding on window.onload has no effect
        asyncLoad()


#</script>