// Generated by CoffeeScript 1.6.1
(function() {
  var ElasticScroll, Q, qhttp;

  Q = require('q');

  qhttp = require('q-io/http');

  ElasticScroll = (function() {

    function ElasticScroll(url, query, process_fn) {
      this.url = url;
      this.query = query;
      this.process_fn = process_fn;
      this.scroll_id = null;
    }

    ElasticScroll.prototype.set_scroll_id = function() {
      var request,
        _this = this;
      request = {
        method: "POST",
        body: [JSON.stringify(this.query)],
        url: "" + this.url + "/_search?search_type=scan&scroll=10m&size=100"
      };
      return qhttp.request(request).then(function(response) {
        return response.body.read();
      }).then(function(resp) {
        return JSON.parse(resp.toString());
      }).then(function(json) {
        console.error("TOTAL:", json.hits.total);
        return _this.scroll_id = json._scroll_id;
      });
    };

    ElasticScroll.prototype.get_next_set = function() {
      var request;
      process.stderr.write(".");
      request = {
        method: "GET",
        url: "" + this.url + "/_search/scroll/" + this.scroll_id + "?scroll=10m"
      };
      return qhttp.request(request).then(function(response) {
        return response.body.read();
      }).then(function(resp) {
        return JSON.parse(resp.toString());
      }).then(function(json) {
        return json.hits.hits;
      });
    };

    ElasticScroll.prototype.process_hits = function(hits) {
      var hit, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = hits.length; _i < _len; _i++) {
        hit = hits[_i];
        _results.push(this.process_fn(hit));
      }
      return _results;
    };

    ElasticScroll.prototype.continue_scroll = function(hits) {
      var _this = this;
      if (hits.length > 0) {
        return this.get_next_set().then(function(hits) {
          return _this.process_hits(hits);
        }).then(function(hits) {
          return _this.continue_scroll(hits);
        });
      } else {
        return console.error("FINISHED");
      }
    };

    ElasticScroll.prototype.scroll = function() {
      var _this = this;
      return Q.fcall(function() {
        return console.error("STARTING");
      }).then(function() {
        return _this.set_scroll_id(_this.query);
      }).then(function() {
        return _this.get_next_set();
      }).then(function(hits) {
        return _this.process_hits(hits);
      }).then(function(hits) {
        return _this.continue_scroll(hits);
      });
    };

    return ElasticScroll;

  })();

  if (typeof define !== 'undefined' && define.amd) {
    define([], function() {
      return ElasticScroll;
    });
  } else if (typeof module !== 'undefined' && module.exports) {
    module.exports = ElasticScroll;
  }

}).call(this);