#ElasticScroll

This is a module that implements the [scrolling api for Elasticsearch](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-request-scroll.html).

To use this module 

```coffeescript
ElasticScroll = require './elasticscroll'

query = {"query": {"term" : "bla"}}

print_to_console = function(hit){console.log(hit)}

es = new ElasticScroll("http://localhost:9200", query, print_to_console)

es.scroll().fail(console.log)
```

Please read the explination of how this works at [maori.geek](http://maori.geek.nz/post/scroll_elasticsearch_using_promises_and_node_js).
