{
  "$schema": "https://www.krakend.io/schema/v3.json",
  "version": 3,
  "name": "KrakenD - API Gateway",
  "timeout": "3000ms",
  "cache_ttl": "300s",
  "endpoints": [
    {
      "endpoint": "/v1/echo",
      "method": "POST",
      "output_encoding": "string",
      "backend": [
        {
          "url_pattern": "/echo",
          "encoding": "string",
          "sd": "static",
          "method": "POST",
          "host": [
            "{{ env "NOMAD_UPSTREAM_ADDR_prototype"}}"
          ],
          "disable_host_sanitize": false
        }
      ]
    }
  ]
}