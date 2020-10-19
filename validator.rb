class Validator
  attr_reader :errors

  def initialize(validation_schema)
    @validation_schema = validation_schema
    @errors = {}
  end

  def validate!(schema)
    validate_hash(validation: @validation_schema, key: nil, schema: schema)
    @errors.empty?
  end

  def valid?
    @errors.empty?
  end

  private

  def validate_hash(validation:, key:, schema:)
    validation.each do |sub_key, sub_validation|
      validate_entry(
        validation: sub_validation,
        key: [key, sub_key].compact.join("."),
        schema: schema[sub_key.to_s]
      )
    end
  end

  def validate_array(validation:, key:, schema:)
    if schema.is_a?(Array)
      schema.each do |sub_schema|
        validate_entry(
          validation: validation.first, # TODO: Why first?
          key: "#{key}.entry",
          schema: sub_schema
        )
      end
    end
  end

  def validate_entry(validation:, key:, schema:)
    check_length(validation: validation, key: key, schema: schema)
    check_depth(validation: validation, key: key, schema: schema)
    check_required(validation: validation, key: key, schema: schema)
    check_type(validation: validation, key: key, schema: schema)
    check_enum(validation: validation, key: key, schema: schema)
    check_match(validation: validation, key: key, schema: schema)

    validationEntry = validation[:entry]
    case validationEntry
    when Array
      validate_array(validation: validationEntry, key: key, schema: schema) if schema
    when Hash
      validate_hash(validation: validationEntry, key: key, schema: schema) if schema
    when nil
      # Nothing, we're done
    else
      raise "invalid entry #{validationEntry}"
    end
  end

  ##
  ## Validators
  ##

  # Fails validation if length is more than specified, or we can't respond to length
  def check_length(validation:, key:, schema:)
    return false unless validation[:length] && schema

    case schema
    when Hash, Array
      return false unless schema.length > validation[:length]
      error!(
        key,
        "cannot have more than #{validation[:length]} "\
        "#{pluralize('element', 'elements', validation[:length])}, "\
        "but has #{schema.length} #{pluralize('element', 'elements', schema.length)}"
      )
    when String
      return false unless schema.length > validation[:length]
      error!(
        key,
        "cannot be longer than #{validation[:length]} "\
        "#{pluralize('character', 'characters', validation[:length])}, but was #{schema.length} in length"
      )
    else
      error!(
        key,
        "cannot validate length on an object of type #{schema.class}. "\
        "Tried to validate length of #{validation[:length]}"
      )
    end

    true
  end

  # Fails validation if depth of nestable types is more than specified
  def check_depth(validation:, key:, schema:)
    return false unless validation[:depth] && schema

    case schema
    when Hash, Array
      depth = max_depth(schema)
      return false unless depth > validation[:depth]
      error!(
        key,
        "cannot have a depth of more than #{validation[:depth]} "\
        "but #{key} has a nested depth of #{depth}"
      )
    else
      error!(
        key,
        "cannot validate depth on an object of type #{schema.class}. "\
        "Tried to validate depth of #{validation[:length]}"
      )
    end

    true
  end

  # Fails validation if required and the value is nil
  def check_required(validation:, key:, schema:)
    return false unless validation[:required] && schema.nil?

    error! key, "was required"
    true
  end

  # Fails validation if the value is not of the 'type' class
  def check_type(validation:, key:, schema:)
    return false if !validation[:required] && schema.nil? # Optional and not here, dont check
    return false unless validation[:type]
    if validation[:type] == 'Boolean'
      return false unless !(schema.is_a?(TrueClass) || schema.is_a?(FalseClass) || schema.nil?)
    else
      return false unless !(schema.is_a?(validation[:type]) || schema.nil?)
    end

    error! key, "supposed to be a #{validation[:type]} but was #{schema.class}"
    true
  end

  # Fails validation if the value is not in values
  def check_enum(validation:, key:, schema:)
    return false if !validation[:required] && schema.nil? # Optional and not here, dont check
    return false unless validation[:values]
    return false if validation[:values].include?(schema)

    schema = 'nothing' if schema.nil?
    error! key, "must be one of #{validation[:values].join(', ')}, but was #{schema}"
    true
  end

  MATCH_REGEX = {
    ip: /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/,
    host: /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/,
  }

  # Fails validation if the value does not match 'matches'
  def check_match(validation:, key:, schema:)
    return false if !validation[:required] && schema.nil? # Optional and not here, dont check
    return false unless validation[:matches]

    matchers = [validation[:matches]].flatten
    return false if matchers.any? { |r| schema =~ MATCH_REGEX[r] }

    error! key, "must match a regex for one of (#{matchers.join(', ')}), but #{schema} did not"
    true
  end

  ##
  ## Helpers
  ##

  def error!(key, msg)
    @errors[key] ||= []
    @errors[key] << msg
  end

  def max_depth(node)
    # Nil node has 0 depth.
    return 0 if node.nil?

    depths = case node
    when Array
      potential_elements = node.select { |el| el.is_a?(Hash) || el.is_a?(Array) }
      potential_elements.map { |el| max_depth(el) }
    when Hash
      potential_elements = node.values.select { |el| el.is_a?(Hash) || el.is_a?(Array) }
      potential_elements.map { |el| max_depth(el) }
    end

    return 1 if depths.empty? # If we are empty, we are at a terminal, return 1
    depths.max + 1 # Otherwise, return the deepest branch, increased by 1 for this level
  end

  def pluralize(singular, plural, count)
    count == 1 ? singular : plural
  end
end
