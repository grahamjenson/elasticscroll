
Q = require 'q'
qhttp = require 'q-io/http'
url = require 'url'
class ElasticScroll

  constructor: (@url, @query, @process_fn) ->
    @scroll_id = null

  set_scroll_id: ->
    request = {
      method: "POST"
      body: [JSON.stringify(@query)]
      url: "#{@url}/_search?search_type=scan&scroll=10m&size=100"
    }

    qhttp.request(request)
    .then((response) -> response.body.read())
    .then((resp) -> JSON.parse(resp.toString()))
    .then((json) => console.error "TOTAL:", json.hits.total; @scroll_id = json._scroll_id)

  get_next_set: () ->
    process.stderr.write(".");
    parsed_url = url.parse(@url)
    host_name = "#{parsed_url.protocol}//#{parsed_url.host}"
    request = {
      method: "GET"
      url: "#{host_name}/_search/scroll/#{@scroll_id}?scroll=10m"
    }
    qhttp.request(request)
    .then((response) -> response.body.read())
    .then((resp) -> JSON.parse(resp.toString()))
    .then((json) -> json.hits.hits)

  process_hits: (hits) ->
    (@process_fn(hit) for hit in hits)

  continue_scroll: (hits) ->
   return if hits.length == 0
   
   @get_next_set()
   .then( (hits) => @process_hits(hits))
   .then( (hits) => @continue_scroll(hits))

  scroll: ->
    Q.fcall(-> console.error "STARTING")
    .then( => @set_scroll_id(@query))
    .then( => @get_next_set())
    .then( (hits) => @process_hits(hits))
    .then( (hits) => @continue_scroll(hits))


#AMD
if (typeof define != 'undefined' && define.amd)
  define([], -> return ElasticScroll)
#Node
else if (typeof module != 'undefined' && module.exports)
    module.exports = ElasticScroll;
