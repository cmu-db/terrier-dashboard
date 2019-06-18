class Dashing.Coverage extends Dashing.Widget

  @accessor 'value', Dashing.AnimatedValue
  @accessor 'bgColor', -> "#999"

  constructor: ->
    super
    @observe 'value', (value) ->
      $(@node).find('.coverage').val(value).trigger('change')

  ready: ->
    meter = $(@node).find('.coverage')
    $(@node).fadeOut().css('background-color', @get('bgColor')).fadeIn()
    meter.attr("data-bgcolor", meter.css("background-color"))
    meter.attr("data-fgcolor", meter.css("color"))
    meter.knob()

  onData: (data) ->
    if data.currentResult isnt data.lastResult
      $(@node).fadeOut().css('background-color', @get('bgColor')).fadeIn()
