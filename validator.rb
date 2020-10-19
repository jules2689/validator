class Validator
  attr_reader :errors

  def initialize(validation_schema)
    @validation_schema = validation_schema
    @errors = {}
  end

  def validate!(schema)
    validate_hash(schema: schema, validation: @validation_schema)
    @errors.empty?
  end

  def valid?
    @errors.empty?
  end

  private

  def validate_hash(schema:, validation:)
    validation.each do |sub_key, sub_validation|
      validate_entry(
        validation: sub_validation,
        key: sub_key,
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
    check_required(validation: validation, key: key, schema: schema)
    check_type(validation: validation, key: key, schema: schema)
    check_enum(validation: validation, key: key, schema: schema)
    check_match(validation: validation, key: key, schema: schema)

    validationEntry = validation[:entry]
    case validationEntry
    when Array
      validate_array(key: key, schema: schema, validation: validationEntry) if schema
    when Hash
      validate_hash(schema: schema, validation: validationEntry) if schema
    when nil
      # Nothing, we're done
    else
      raise "invalid entry #{validationEntry}"
    end
  end

  ##
  ## Validators
  ##

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

  def error!(key, msg)
    @errors[key] ||= []
    @errors[key] << msg
  end
end
