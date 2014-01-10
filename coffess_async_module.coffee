#<script type="text/coffeescript" target="/home/wangyu/IdeaProjects/piao/1227/src/static/js/widget/async_module.js">
###
    init auto load event
###
do ()->
    # create style for async-module
#    $("<style type='text/css'> .async-module{display: none} </style>").appendTo("head");

    modules = $ '.async-module'
    $win = $ window

    asyncLoad = (preDistance = 0)->
        for _obj, index in modules
            #console.log "handle #{index}/#{modules.length}"
            obj = modules.eq(index)
            if obj.offset().top < ($win.scrollTop() + $win.height() + preDistance)
                #console.log "loadmodule #{obj.attr('data-load-module')}"
                obj.loadModule()

                # only one module will not walk through the clear function in the else statement
                if index == modules.length - 1 then modules = modules.slice(index+1)
            else
                #console.log "later #{index}"
                if index > 0
                    modules = modules.slice(index)
                break

        if modules.length == 0
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
        asyncLoadTrigger()

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

CONFIG =
    DEBUG: true && location.search.indexOf('AD') isnt -1

if CONFIG.DEBUG is true
    CONFIG.bufferHeight =  -100

Debugger =
    id: 0
    showInfo: (target)->
        type = target.data 'type'
#        switch type
#            when 'tmpl'
#
#            else
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

    init: do ()->
        return if !CONFIG.DEBUG
        $("""<style type='text/css'>
          .amd {background: #CCE8CF}
        .amd .title{background: lightgreen}
        .amd .em {color: darkred; font-weight: bold}
        .amd textarea{display: none}
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

jQueryLoadModule = ()->
    try
        type = this.data 'type'


        switch type
            when 'tmpl'
                # load tmpl content in the script tag
                tmpl = this.children()
                this.html(tmpl.html())
            else
                # check if need async load by check the existance of '<\!--'
                origin = this.html().replace(/(^\s*)|(\s*$)/g, "")
                # no need to aysnc load this since it's not wrapped by '<\!-- -->'
                return if origin.indexOf('<\!--') is -1

                # out put debug info
                tools.debug(this);

                # extract js && css, left html
                source = origin.replace(/(<\!--)|(-->)/g, "")
                tools.loadHtml(source, this)

    catch e
        if console then console.log e.stack

# exposed as jquery plugin
$.fn.loadModule = jQueryLoadModule
#</script>