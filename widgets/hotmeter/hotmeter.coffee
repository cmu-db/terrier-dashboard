class Dashing.Hotmeter extends Dashing.Widget

  @accessor 'value', Dashing.AnimatedValue

  constructor: ->
    super
    @observe 'value', (value) ->
      $(@node).find(".meter").val(value).trigger('change')

  ready: ->
    meter = $(@node).find(".meter")
    meter.attr("data-bgcolor", meter.css("background-color"))
    meter.attr("data-fgcolor", meter.css("color"))
    meter.knob()

  onData: (data) ->
    node = $(@node)
    value = parseInt data.value
    cool = parseInt node.data "cool"
    warm = parseInt node.data "warm"
    level = switch
      when value <= cool then 0
      when value >= warm then 4
      else 
        bucketSize = (warm - cool) / 3 # Total # of colours in middle
        Math.ceil (value - cool) / bucketSize
  
    backgroundClass = "hotness#{level}"
    lastClass = @get "lastClass"
    node.toggleClass "#{lastClass} #{backgroundClass}"
    @set "lastClass", backgroundClass  