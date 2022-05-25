# Memery   [![Gem Version](https://badge.fury.io/rb/memery.svg)](https://badge.fury.io/rb/memery) ![Build Status](https://github.com/tycooon/memery/actions/workflows/ci.yml/badge.svg) [![Coverage Status](https://coveralls.io/repos/github/tycooon/memery/badge.svg?branch=master)](https://coveralls.io/github/tycooon/memery?branch=master)

Memery is a Ruby gem for memoization of method return values. The normal memoization in Ruby doesn't require any gems and looks like this:

```ruby
def user
  @user ||= User.find(some_id)
end
```

However, this approach doesn't work if calculated result can be `nil` or `false` or in case the method is using arguments. You will also require extra `begin`/`end` lines in case your method requires multiple lines:

```ruby
def user
  @user ||= begin
    some_id = calculate_id
    klass = calculate_klass
    klass.find(some_id)
  end
end
```

For all these situations memoization gems (like this one) exist. The last example can be rewritten using memery like this:

```ruby
memoize def user
  some_id = calculate_id
  klass = calculate_klass
  klass.find(some_id)
end
```

## Installation

Simply add `gem "memery"` to your Gemfile.

## Usage

```ruby
class A
  include Memery

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

a = A.new
a.call # => 42
a.call # => 42
a.call # => 42
# Text will be printed only once.

a.call { 1 } # => 42
# Will print because passing a block disables memoization
```

Methods with arguments are supported and the memoization will be done based on arguments using an internal hash. So this will work as expected:

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
# Text will be printed only twice, once per unique argument list.
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
# Text will be printed only once.
```

For conditional memoization:

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

For memoization with time-to-live:

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

Check if method is memoized:

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

## Difference with other gems
Memery is very similar to [Memoist](https://github.com/matthewrudy/memoist). The difference is that it doesn't override methods, instead it uses Ruby 2 `Module.prepend` feature. This approach is cleaner (for example you are able to inspect the original method body using `method(:x).super_method.source`) and it allows subclasses' methods to work properly: if you redefine a memoized method in a subclass, it's not memoized by default, but you can memoize it normally (without using awkward `identifier: ` argument) and it will just work:

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

Note how both method's return values are cached separately and don't interfere with each other.

The other key difference is that it doesn't change method's signature (no extra `reload` param). If you need to get unmemoized result of method, just create an unmemoized version like this:

```ruby
memoize def users
  get_users
end

def get_users
  # ...
end
```

Alternatively, you can clear the whole instance's cache:

```ruby
a.clear_memery_cache!
```

Finally, you can provide a block:

```ruby
a.users {}
```

However, this solution is kind of hacky.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tycooon/memery.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Author

Created by Yuri Smirnov.
