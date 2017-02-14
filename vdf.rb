require 'strscan'

class VDF
  attr_reader :scanner

  def initialize(string, allow_duplicate_keys)
    @allow_duplicate_keys = allow_duplicate_keys
    @scanner = StringScanner.new(string)
  end

  def translate
    parse
  end

  def parse
    until scanner.eos?
      @oldpos = scanner.pos
      if comment || ignorable
      elsif hash_head
        return scanner[1] => kvs
      else scan(/./m)
        # p any: s.matched
      end

      if @oldpos == scanner.pos
        raise scanner.inspect
      end
    end
  rescue => ex
    puts ex, *ex.backtrace
    p @scanner
  end

  def ignorable
    while space || comment
    end
  end

  def comment
    scan(/\s*\/.*/)
  end

  def space
    scan(/\s+/m)
  end

  def string
    if scan(/""/)
      ""
    else scan(/"((\\"|[^"])+)"/)
      scanner[1]
    end
  end

  def hash_head
    scan(/"([^"]*)"(\s|\s*\/[^\r\n]+)*\{/m)
  end

  def hash_tail
    space
    scan(/\}/)
  end

  def null_byte
    scan(/\0/)
  end

  def kv_pair
    [string, space, string]
  end

  def kvs
    hash = {}

    until hash_tail || scanner.eos?
      @oldpos = scanner.pos
      ignorable
      if hash_head
        key = scanner[1]
        value = kvs
        if @allow_duplicate_keys && hash.key?(key)
          hash[key] = [hash[key]] unless hash[key].is_a?(Array)
          hash[key] << value
        else
          hash[key] = value
        end
        ignorable
      elsif key = string
        ignorable
        if value = string
          if @allow_duplicate_keys && hash.key?(key)
            hash[key] = [hash[key]] unless hash[key].is_a?(Array)
            hash[key] << value
          else
            hash[key] = value
          end
        else
          raise "expected value"
        end
      elsif hash_tail
        # nothing to do here
      elsif null_byte
        # EOF
        break
      else
        raise "expected key"
      end

      ignorable

      if @oldpos == scanner.pos
        raise scanner.inspect
      end
    end

    kvs_transmute hash
  end

  def scan(*a)
    scanner.scan(*a)
  end

  def kvs_transmute(hash)
    if var_type = hash.delete('var_type')
      key, value = hash.first

      case var_type
      when 'FIELD_INTEGER'
        if value =~ /\s/
          hash = {key => value.split.map{|i| i.to_i }}
        else
          hash = {key => value.to_i}
        end
      when 'FIELD_FLOAT'
        if value =~ /\s/
          hash = {key => value.scan(/[\d.]+/).map{|i| Float(i) }}
        else
          hash = {key => Float(value[/[\d.]+/])}
        end
      else
        raise var_type
      end
    elsif hash.keys.all?{|k| k =~ /^\s*\d+\s*$/ }
      hash.sort_by{|k,v| k.to_i }.map{|k,v| v }
    else
      hash
    end
  end
end
