<source>
  @type forward
  @label @mainstream
  port {{ env "NOMAD_PORT_http" }}
  bind 0.0.0.0
</source>
<filter **>
  @type stdout
</filter>
<label @mainstream>
  <match *-group>
      @type elasticsearch
      scheme http
      host {{ env "NOMAD_UPSTREAM_IP_elasticsearch"}}
      port {{ env "NOMAD_UPSTREAM_PORT_elasticsearch"}}
      @log_level debug
      logstash_format true
      logstash_dateformat %Y-%m-%d
      logstash_prefix log-${tag}
      include_tag_key true
      <buffer>
        flush_interval 10s
      </buffer>
  </match>
</label>