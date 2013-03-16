( (factory) ->
  # Uses AMD or browser globals to create a jQuery plugin.
  # It does not try to register in a CommonJS environment since
  # jQuery is not likely to run in those environments.
  #
  # form [umd](https://github.com/umdjs/umd) project
  if typeof define is 'function' and define.amd
    # Register as an anonymous AMD module:
    define ['jquery'], factory
  else
    # Browser globals
    factory window.jQuery
) ($) ->
  # @example
  #   mirror = new Mirror($("textarea#inputor"))
  #   html = "<p>We will get the rect of <span>@</span>icho</p>"
  #   mirror.create(html).get_flag_rect()
  class Mirror
    css_attr: [
      "overflowY", "height", "width", "paddingTop", "paddingLeft",
      "paddingRight", "paddingBottom", "marginTop", "marginLeft",
      "marginRight", "marginBottom","fontFamily", "borderStyle",
      "borderWidth","wordWrap", "fontSize", "lineHeight", "overflowX",
      "text-align",
    ]

    # @param $inputor [Object] 输入框的 jQuery 对象
    constructor: (@$inputor) ->

    # 克隆输入框的样式
    #
    # @return [Object] 返回克隆得到样式
    copy_inputor_css: ->
      css =
        position: 'absolute'
        left: -9999
        top:0
        zIndex: -20000
        'white-space': 'pre-wrap'
      $.each @css_attr, (i,p) =>
        css[p] = @$inputor.css p
      css

    # 在页面中创建克隆后的镜像.
    #
    # @param html [String] 将输入框内容转换成 html 后的内容.
    #   主要是为了给 `flag` (@, etc.) 打上标记
    #
    # @return [Object] 返回当前对象
    create: (html) ->
      @$mirror = $('<div></div>')
      @$mirror.css this.copy_inputor_css()
      @$mirror.html(html)
      @$inputor.after(@$mirror)
      this

    # 获得标记的位置
    #
    # @return [Object] 标记的坐标
    #   {left: 0, top: 0, bottom: 0}
    get_flag_rect: ->
      $flag = @$mirror.find "span#flag"
      pos = $flag.position()
      rect = {left: pos.left, top: pos.top, bottom: $flag.height() + pos.top}
      @$mirror.remove()
      rect

    @offset: ($inputor, html) ->
      this.constructor $inputor
      this.create(html).get_flag_rect()


  format = (value) ->
    value.replace(/</g, '&lt')
    .replace(/>/g, '&gt')
    .replace(/`/g,'&#96')
    .replace(/"/g,'&quot')
    .replace(/\r\n|\r|\n/g,"<br />")

  offset_for_ie = ->
    Sel = document.selection.createRange()
    x = Sel.boundingLeft + $inputor.scrollLeft()
    y = Sel.boundingTop + $(window).scrollTop() + $inputor.scrollTop()
    bottom = y + Sel.boundingHeight
      # -2 : for some font style problem.
    return {left: x-2, top: y-2,  bottom:bottom-2}

  offset = ($inputor) ->

    ### 克隆完inputor后将原来的文本内容根据
      @的位置进行分块,以获取@块在inputor(输入框)里的position
    ###
    pos = $inputor.caretPos()
    start_range = $inputor.val().slice(0, pos)
    html = "<span>"+format(start_range)+"</span>"
    html += "<span id='flag'>?</span>"

    ###
      将inputor的 offset(相对于document)
      和@在inputor里的position相加
      就得到了@相对于document的offset.
      当然,还要加上行高和滚动条的偏移量.
    ###
    offset = $inputor.offset()
    at_rect = Mirror.offset($inputor, html)

    x = offset.left + at_rect.left - $inputor.scrollLeft()
    y = offset.top - $inputor.scrollTop()
    bottom = y + at_rect.bottom
    y += at_rect.top

    # bottom + 2: for some font style problem
    return {left: x, top: y, bottom:bottom + 2}

  $.fn.caretOffset = ->
    if document.selection # for IE full
      offset_for_ie()
    else
      offset($(this[0]))
