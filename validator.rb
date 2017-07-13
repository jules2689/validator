class Validator
  attr_reader :errors

  def initialize(validation)
    @validation = validation
    @errors = {}
  end

  def validate!(args)
    validate_hash(args, @validation)
    @errors.empty?
  end

  def valid?
    @errors.empty?
  end

  private

  def validate_entry(validation, key, val)
    check_required(key, val, validation)
    check_type(key, val, validation)
    check_enum(key, val, validation)
    check_match(key, val, validation)

    entry = validation[:entry]
    case entry
    when Array
      validate_array(key, val, validation[:type], entry) if val
    when Hash
      validate_hash(val, entry) if val
    when nil
      # Nothing, we're done
    else
      raise "invalid entry #{entry}"
    end
  end

  def validate_array(key, val, type, entry)
    raise 'Cannot provide an entry array if type is not Array' unless type == Array
    if val.is_a?(Array)
      val.each do |sub_val|
        validate_entry(entry.first, "#{key}.entry", sub_val)
      end
    end
  end

  def validate_hash(val, entry)
    entry.each do |sub_key, sub_entry|
      validate_entry(sub_entry, sub_key, val[sub_key.to_s])
    end
  end

  ##
  ## Validators
  ##

  # Fails validation if required and the value is nil
  def check_required(key, val, validation)
    return false unless validation[:required] && val.nil?

    error! key, "was required"
    true
  end

  # Fails validation if the value is not of the 'type' class
  def check_type(key, val, validation)
    return false if !validation[:required] && val.nil? # Optional and not here, dont check
    return false unless validation[:type]
    if validation[:type] == 'Boolean'
      return false unless !(val.is_a?(TrueClass) || val.is_a?(FalseClass) || val.nil?)
    else
      return false unless !(val.is_a?(validation[:type]) || val.nil?)
    end

    error! key, "supposed to be a #{validation[:type]} but was #{val.class}"
    true
  end

  # Fails validation if the value is not in values
  def check_enum(key, val, validation)
    return false if !validation[:required] && val.nil? # Optional and not here, dont check
    return false unless validation[:values]
    return false if validation[:values].include?(val)

    val = 'nothing' if val.nil?
    error! key, "must be one of #{validation[:values].join(', ')}, but was #{val}"
    true
  end

  MATCH_REGEX = {
    ip: /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/,
    host: /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/,
  }

  # Fails validation if the value does not match 'matches'
  def check_match(key, val, validation)
    return false if !validation[:required] && val.nil? # Optional and not here, dont check
    return false unless validation[:matches]

    matchers = [validation[:matches]].flatten
    return false if matchers.any? { |r| val =~ MATCH_REGEX[r] }

    error! key, "must match a regex for one of (#{matchers.join(', ')}), but #{val} did not"
    true
  end

  def error!(key, msg)
    @errors[key] ||= []
    @errors[key] << msg
  end
end
