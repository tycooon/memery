# Mememaster

Mememaster is a gem for memoization in Ruby. Example:

```ruby
class A
  memoize def call
    puts "calculating"
    42
  end

  # or:
  # def call
  #   ...
  # end
  # memoize :call
end

A.new.call # => 42
A.new.call # => 42
A.new.call # => 42

# Text will be printed inly once.
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
