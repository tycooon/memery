# Memery   [![Gem Version](https://badge.fury.io/rb/memery.svg)](https://badge.fury.io/rb/memery) ![Build Status](https://github.com/tycooon/memery/actions/workflows/ci.yml/badge.svg) [![Coverage Status](https://coveralls.io/repos/github/tycooon/memery/badge.svg?branch=master)](https://coveralls.io/github/tycooon/memery?branch=master)

Memery is a Ruby gem that simplifies memoization of method return values. In Ruby, memoization typically looks like this:

```ruby
def user
  @user ||= User.find(some_id)
end
```

However, this approach fails if the calculated result can be `nil` or `false`, or if the method uses arguments. Additionally, multi-line methods require extra `begin`/`end` blocks:

```ruby
def user
  @user ||= begin
    some_id = calculate_id
    klass = calculate_klass
    klass.find(some_id)
  end
end
```

To handle these situations, memoization gems like Memery exist. The example above can be rewritten using Memery as follows:

```ruby
memoize def user
  some_id = calculate_id
  klass = calculate_klass
  klass.find(some_id)
end
```

## Installation

Add `gem "memery"` to your Gemfile.

## Usage

```ruby
class A
  include Memery

  memoize def call
    puts "calculating"
    42
  end

  # Alternatively:
  # def call
  #   ...
  # end
  # memoize :call
end

a = A.new
a.call # => 42
a.call # => 42
a.call # => 42
# "calculating" will only be printed once.

a.call { 1 } # => 42
# "calculating" will be printed again because passing a block disables memoization.
```

Memoization works with methods that take arguments. The memoization is based on these arguments using an internal hash, so the following will work as expected:

```ruby
class A
  include Memery

  memoize def call(arg1, arg2)
    puts "calculating"
    arg1 + arg2
  end
end

a = A.new
a.call(1, 5) # => 6
a.call(2, 15) # => 17
a.call(1, 5) # => 6
# "calculating" will be printed twice, once for each unique argument list.
```

For class methods:

```ruby
class B
  class << self
    include Memery

    memoize def call
      puts "calculating"
      42
    end
  end
end

B.call # => 42
B.call # => 42
B.call # => 42
# "calculating" will only be printed once.
```

### Conditional Memoization

```ruby
class A
  include Memery

  attr_accessor :environment

  def call
    puts "calculating"
    42
  end

  memoize :call, condition: -> { environment == 'production' }
end

a = A.new
a.environment = 'development'
a.call # => 42
# calculating
a.call # => 42
# calculating
a.call # => 42
# calculating
# Text will be printed every time because result of condition block is `false`.

a.environment = 'production'
a.call # => 42
# calculating
a.call # => 42
a.call # => 42
# Text will be printed only once because there is memoization
# with `true` result of condition block.
```

### Memoization with Time-to-Live (TTL)

```ruby
class A
  include Memery

  def call
    puts "calculating"
    42
  end

  memoize :call, ttl: 3 # seconds
end

a = A.new
a.call # => 42
# calculating
a.call # => 42
a.call # => 42
# Text will be printed again only after 3 seconds of time-to-live.
# 3 seconds later...
a.call # => 42
# calculating
a.call # => 42
a.call # => 42
# another 3 seconds later...
a.call # => 42
# calculating
a.call # => 42
a.call # => 42
```

### Checking if a Method is Memoized

```ruby
class A
  include Memery

  memoize def call
    puts "calculating"
    42
  end

  def execute
    puts "non-memoized"
  end
end

a = A.new

a.memoized?(:call) # => true
a.memoized?(:execute) # => false
```

### Marshal-compatible Memoization

In order for objects to be marshaled and loaded in a different Ruby process,
hashed arguments must be disabled in order for memoized values to be retained.
Note that this can have a performance impact if the memoized method contains
arguments.

```ruby
Memery.use_hashed_arguments = false

class A
  include Memery

  memoize def call
    puts "calculating"
    42
  end
end

a = A.new
a.call

Marshal.dump(a)
# => "\x04\bo:\x06A\x06:\x1D@_memery_memoized_values{\x06:\tcallS:3Memery::ClassMethods::MemoizationModule::Cache\a:\vresulti/:\ttimef\x14663237.14822323"

# ...in another Ruby process:
a = Marshal.load("\x04\bo:\x06A\x06:\x1D@_memery_memoized_values{\x06:\tcallS:3Memery::ClassMethods::MemoizationModule::Cache\a:\vresulti/:\ttimef\x14663237.14822323")
a.call # => 42
```

## Differences from Other Gems

Memery is similar to [Memoist](https://github.com/matthewrudy/memoist), but it doesn't override methods. Instead, it uses Ruby 2's `Module.prepend` feature. This approach is cleaner, allowing you to inspect the original method body with `method(:x).super_method.source`, and it ensures that subclasses' methods function properly. If you redefine a memoized method in a subclass, it won't be memoized by default. You can memoize it normally without needing an awkward `identifier: ` argument, and it will just work:

```ruby
class A
  include Memery

  memoize def x(param)
    param
  end
end

class B < A
  memoize def x(param)
    super(2) * param
  end
end

b = B.new
b.x(1) # => 2
b.x(2) # => 4
b.x(3) # => 6

b.instance_variable_get(:@_memery_memoized_values)
# => {:x_70318201388120=>{[1]=>2, [2]=>4, [3]=>6}, :x_70318184636620=>{[2]=>2}}
```

Note how both methods' return values are cached separately without interfering with each other.

Another key difference is that Memery doesn't change the method's signature (no extra `reload` parameter). If you need an unmemoized result, simply create an unmemoized version of the method:

```ruby
memoize def users
  get_users
end

def get_users
  # ...
end
```

Alternatively, you can clear the entire instance's cache:

```ruby
a.clear_memery_cache!
```

You can also provide a block, though this approach is somewhat hacky:

```ruby
a.users {}
```

## Object Shape Optimization

In Ruby 3.2, a new optimization called "object shape" was introduced, which can have negative interactions with dynamically added instance variables. Memery minimizes this impact by introducing only one new instance variable after initialization (`@_memery_memoized_values`). If you need to ensure a specific object shape, you can call `clear_memery_cache!` in your initializer to set the instance variable ahead of time.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tycooon/memery.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Author

Created by Yuri Smirnov.
