# Hacked up implementation of this gem for RubyMotion:
# https://github.com/junegunn/si

class SI

  PREFIXES = {
    -8 => 'y',
    -7 => 'z',
    -6 => 'a',
    -5 => 'f',
    -4 => 'p',
    -3 => 'n',
    -2 => 'μ',
    -1 => 'm',
     0 => '',
     1 => 'k',
     2 => 'M',
     3 => 'G',
     4 => 'T',
     5 => 'P',
     6 => 'E',
     7 => 'Z',
     8 => 'Y'
  }

  DEFAULT = {
    :length  =>    2,
    :base    => 1000,
    :min_exp =>   -8,
    :max_exp =>    8,
  }

  def self.convert num, options = {}
    options = { :length => options } if options.is_a?(Fixnum)
    options = DEFAULT.merge(options)
    length,
    min_exp,
    max_exp = options.values_at(:length, :min_exp, :max_exp)
    raise ArgumentError.new("Invalid length") if length < 2
    return num.is_a?(Fixnum) ? '0' : "0.#{'0' * (length - 1)}" if num == 0

    base    = options[:base].to_f
    minus   = num < 0 ? '-' : ''
    nump    = num.abs

    PREFIXES.keys.sort.reverse.select { |exp| (min_exp..max_exp).include? exp }.each do |exp|
      denom = base ** exp
      if nump >= denom || exp == min_exp
        val = nump / denom
        val = SI.round val, [length - val.to_i.to_s.length, 0].max
        val = val.to_i if exp == 0 && num.is_a?(Fixnum)
        val = val.to_s.ljust(length + 1, '0') if val.is_a?(Float)

        return "#{minus}#{val}#{PREFIXES[exp]}"
      end
    end

    nil
  end

  def revert str, options = {}
    options = Hash[ DEFAULT.select { |k, v| k == :base } ].merge(options)
    pair    = PREFIXES.to_a.find { |k, v| !v.empty? && str =~ /[0-9]#{v}$/ }

    if pair
      str[0...-1].to_f * (options[:base] ** pair.first)
    else
      str.to_f
    end
  end

  def self.round val, ndigits
    val.round ndigits
  end

end
