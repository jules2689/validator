require 'yaml'
require_relative 'validator'

def length_validation
  {
    config: {
      type: Hash,
      required: true,
      length: 2
    },
    configArray: {
      type: Array,
      required: true,
      length: 2
    },
    configHashNested: {
      type: Hash,
      required: true,
      entry: {
        thing: {
          type: Array,
          length: 2,
        }
      }
    }
  }
end

def length_valid_config
  config=<<-EOF
  config:
    host: 192.168.1.1
    host2: example.com
  configArray: [1, 2]
  configHashNested:
    thing: [1, 2]
  EOF
  YAML.load(config)
end

def length_hash_invalid_config
  config=<<-EOF
  config:
    host: 192.168.1.1
    host2: example.com
    thing3: foo
  configArray: [1, 2]
  configHashNested:
    thing: [1, 2]
  EOF
  YAML.load(config)
end

def length_array_invalid_config
  config=<<-EOF
  config:
    host: 192.168.1.1
    host2: example.com
  configArray: [1, 2, 3]
  configHashNested:
    thing: [1, 2]
  EOF
  YAML.load(config)
end

def length_nested_hash_invalid_config
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
