require 'yaml'
require_relative 'validator'

def depth_validation
  {
    config: {
      type: Hash,
      required: true,
      depth: 2
    },
    configArray: {
      type: Array,
      required: true,
      depth: 1
    },
  }
end

def depth_valid_config
  config=<<-EOF
  config:
    host: 192.168.1.1
    host2:
      url: example.com
  configArray: [1, 2]
  EOF
  YAML.load(config)
end

def depth_hash_invalid_config
  config=<<-EOF
  config:
    host: 192.168.1.1
    host2:
      thing3:
        url: foo.com
  configArray: [1, 2]
  EOF
  YAML.load(config)
end

def depth_array_invalid_config
  config=<<-EOF
  config:
    host: 192.168.1.1
    host2: example.com
  configArray: [1, 2, [3]]
  EOF
  YAML.load(config)
end

def depth_nested_hash_invalid_config
  config=<<-EOF
  config:
    host: 192.168.1.1
    host2: example.com
  configArray: [1, 2]
  configHashNested:
    thing: [1, 2, 3]
  EOF
  YAML.load(config)
end

def depth_string_invalid_config
  config=<<-EOF
  config:
    host: 192.168.1.1
    host2: example.com
  configArray: [1, 2]
  configHashNested:
    thing: [1, 2]
  string: "1234567"
  EOF
  YAML.load(config)
end
