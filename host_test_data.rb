require 'yaml'
require_relative 'validator'

def host_validation
  {
    config: {
      type: Hash,
      required: true,
      entry: {
        host: {
          type: String,
          required: true,
          matches: [:ip, :host]
        },
        host2: {
          type: String,
          matches: [:ip, :host]
        }
      }
    }
  }
end

def host_valid_config
  config=<<-EOF
  config:
    host: 192.168.1.1
    host2: shopify.com
  EOF
  YAML.load(config)
end

def host_invalid_config
  config=<<-EOF
  config:
    host: not_a_host
  EOF
  YAML.load(config)
end
