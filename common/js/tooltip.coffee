tooltip_hide_id = null
class ToolTipBase extends Widget
    delay_time: 0
    constructor: (@buddy, @text, @parent=document.body)->
        super

    set_delay_time: (millseconds) ->
        ToolTipBase.delay_time = millseconds

    set_text: (text)->
        @text = text

    bind_events: ->
        @buddy.addEventListener('dragstart', @hide)
        @buddy.addEventListener('dragenter', @hide)
        @buddy.addEventListener('dragover', @hide)
        @buddy.addEventListener('dragleave', @hide)
        @buddy.addEventListener('dragend', @hide)
        @buddy.addEventListener('contextmenu', @hide)
        @buddy.addEventListener('mouseout', @hide)
        @buddy.addEventListener('mouseover', =>
            if @text == ''
                return
            clearTimeout(tooltip_hide_id)
            tooltip_hide_id = setTimeout(=>
                @show()
            , ToolTipBase.delay_time)
        )
        @buddy.addEventListener('click', @hide)

    hide: =>
        clearTimeout(tooltip_hide_id)


class ToolTip extends ToolTipBase
    @tooltip: null
    constructor: (@buddy, @text, @parent=document.body)->
        super
        ToolTip.tooltip ?= create_element("div", "tooltip", @parent)
        @bind_events()

    show: ->
        ToolTip.tooltip.innerText = @text
        ToolTip.tooltip.style.display = "block"
        @_move_tooltip()

    hide: =>
        super
        ToolTip.tooltip?.style.display = "none"

    @move_to: (self, x, y) ->
        if y <= 0
            self.hide()
            return
        ToolTip.tooltip.style.left = "#{x}px"
        ToolTip.tooltip.style.bottom = "#{y}px"

    _move_tooltip: ->
        page_xy= get_page_xy(@buddy, 0, 0)
        offset = (@buddy.clientWidth - ToolTip.tooltip.clientWidth) / 2

        x = page_xy.x + offset
        x = 0 if x < 0
        ToolTip.move_to(@, x.toFixed(), document.body.clientHeight - page_xy.y)


class ArrowToolTip extends ToolTipBase
    @container: null
    @tooltip: null
    @arrow: null
    constructor: (@buddy, @text, @parent=document.body)->
        super(@buddy, @text, @parent)
        ArrowToolTip.container ?= create_element('div', 'arrow_tooltip_container ', @parent)
        ArrowToolTip.tooltip ?= create_element('canvas', 'arrow_tooltip', ArrowToolTip.container)
        ArrowToolTip.content ?= create_element('div', 'arrow_tooltip_content', ArrowToolTip.container)
        # content will show wried, have to use _hidden_content
        ArrowToolTip._hidden_content ?= create_element('div', 'arrow_tooltip_hidden_content', @parent)
        @bind_events()

    draw: ->
        content = ArrowToolTip._hidden_content
        canvas = ArrowToolTip.tooltip
        ctx = canvas.getContext('2D')
        # triangle of tooltip
        # |<- width ->|
        # _________________
        # \           /   ^
        #  \         /    |
        #   \       /     |
        #    \     /    height
        #     \   /       |
        #      \ /        |
        #       v_________v
        triangle =
            width: 18
            height: 10
        padding =
            horizontal: 5
            vertical: 0
        radius = 8
        offsetForShadow = 5
        offsetForRadius = 4
        height = content.clientHeight - offsetForRadius * 2

        canvas.width = content.clientWidth + 2 * (padding.horizontal + radius + offsetForShadow)
        canvas.height = height + 2 * (padding.vertical + radius + offsetForShadow) + triangle.height
        ArrowToolTip.container.width = canvas.width
        ArrowToolTip.container.height = canvas.height

        topY = offsetForShadow + radius
        bottomY = topY + height + padding.vertical * 2
        leftX = offsetForShadow + radius
        rightX = leftX + 2 * padding.horizontal + content.clientWidth

        arch =
            TopLeft:
                ox: leftX
                oy: topY
                radius: radius
                startAngle: Math.PI
                endAngle: Math.PI * 1.5
            TopRight:
                ox: rightX
                oy: topY
                radius: radius
                startAngle: Math.PI * 1.5
                endAngle: Math.PI * 2
            BottomRight:
                ox: rightX
                oy: bottomY
                radius: radius
                startAngle: 0
                endAngle: Math.PI * 0.5
            BottomLeft:
                ox: leftX
                oy: bottomY
                radius: radius
                startAngle: Math.PI * 0.5
                endAngle: Math.PI

        ctx = canvas.getContext('2d')
        ctx.save()
        # ctx.globalAlpha = 0.8
        ctx.beginPath()

        ctx.moveTo(offsetForShadow, topY)
        ctx.arc(arch['TopLeft'].ox, arch['TopLeft'].oy, arch['TopLeft'].radius,
                arch['TopLeft'].startAngle, arch['TopLeft'].endAngle)

        ctx.lineTo(rightX, offsetForShadow)

        ctx.arc(arch['TopRight'].ox, arch['TopRight'].oy, arch['TopRight'].radius,
                arch['TopRight'].startAngle, arch['TopRight'].endAngle)

        ctx.lineTo(rightX + radius, bottomY)

        ctx.arc(arch['BottomRight'].ox, arch['BottomRight'].oy, arch['BottomRight'].radius,
                arch['BottomRight'].startAngle, arch['BottomRight'].endAngle)

        # bottom line
        ctx.lineTo(leftX + padding.horizontal + (content.clientWidth + triangle.width) / 2,
                   bottomY + radius)

        # triangle
        ctx.lineTo(leftX + padding.horizontal + content.clientWidth / 2,
                   bottomY + radius + triangle.height)

        ctx.lineTo(leftX + padding.horizontal + (content.clientWidth - triangle.width)/2,
                   bottomY + radius)

        # bottom line
        ctx.lineTo(leftX, bottomY + radius)

        ctx.arc(arch['BottomLeft'].ox, arch['BottomLeft'].oy, arch['BottomLeft'].radius,
                arch['BottomLeft'].startAngle, arch['BottomLeft'].endAngle)
        ctx.closePath()

        ctx.shadowBlur = 7
        ctx.shadowColor = 'rgba(0,0,0,0.5)'
        ctx.shadowOffsetY = 1

        ctx.strokeStyle = 'rgba(255,255,255, 0.7)'
        ctx.lineWidth = 1
        ctx.stroke()

        grd = ctx.createLinearGradient(0, 0, 0, height + 2 * padding.vertical + radius * 2 + triangle.height)
        grd.addColorStop(0, 'rgba(0,0,0,0.7)')
        grd.addColorStop(1, 'rgba(0,0,0,0.9)')
        ctx.fillStyle = grd
        ctx.fill()

        ctx.restore()

        ArrowToolTip.content.style.top = offsetForShadow + padding.vertical + radius - offsetForRadius
        ArrowToolTip.content.style.left = offsetForShadow + padding.horizontal + radius

    show: =>
        ArrowToolTip.container.style.display = "block"
        ArrowToolTip.container.style.opacity = 1
        ArrowToolTip.content.style.display = "block"
        ArrowToolTip.content.textContent = @text
        ArrowToolTip._hidden_content.textContent = @text
        @draw()
        @_move_tooltip()

    hide: =>
        super
        ArrowToolTip.container.style.display = 'none'
        ArrowToolTip.container.style.opacity = 0

    @move_to: (self, x, y) ->
        if y <= 0
            self.hide()
            return
        ArrowToolTip.container.style.left = "#{x}px"
        ArrowToolTip.container.style.bottom = "#{y}px"

    _move_tooltip: ->
        page_xy= get_page_xy(@buddy, 0, 0)
        offset = (@buddy.clientWidth - ArrowToolTip.container.clientWidth) / 2

        x = page_xy.x + offset
        x = 0 if x < 0
        y = document.body.clientHeight - page_xy.y - 2 # 7 for subtle
        ArrowToolTip.move_to(@, x.toFixed(), y)
