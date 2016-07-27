Promise = require 'bluebird'
request = Promise.promisify(require 'request')
url = require 'url'

class ElasticScroll

  constructor: (@hostname, @index, @scroll_size, @query, @process_fn) ->
    @scroll_id = null

  set_scroll_id: ->
    request({
      method: "POST"
      body: JSON.stringify(@query)
      url: "#{@hostname}/#{@index}/_search?search_type=scan&scroll=60m&size=#{@scroll_size}"
    })
    .then((resp) -> JSON.parse(resp.body))
    .then((json) => console.error "TOTAL:", json.hits.total; @scroll_id = json._scroll_id)

  get_next_set: () ->
    process.stderr.write(".");
    request({
      method: "GET"
      url: "#{@hostname}/_search/scroll/#{@scroll_id}?scroll=60m"
    })
    .then((resp) -> JSON.parse(resp.body))
    .then((json) -> json.hits.hits)

  process_hits: (hits) ->
    Promise.try( => @process_fn(hits))
    .then( -> hits)

  continue_scroll: (hits) ->
    return if hits.length == 0

    @get_next_set()
    .then( (hits) => @process_hits(hits))
    .then( (hits) => @continue_scroll(hits))

  scroll: ->
    console.log "Starting"
    @set_scroll_id(@query)
    .then( => @get_next_set())
    .then( (hits) => @process_hits(hits))
    .then( (hits) => @continue_scroll(hits))


module.exports = ElasticScroll

