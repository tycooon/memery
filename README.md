# Alt Memery

Alt Memery allows to memoize methods return values.

The native simplest memoization in Ruby looks like this:

```ruby
def user
  @user ||= User.find(some_id)
end
```

But if you want to memoize falsy values — you have to use `defined?` instead of `||=`:

```ruby
def user
  return @user if defined?(@user)

  @user = User.find(some_id)
end
```

But with memoization gems, like this one, you can simplify your code:

```ruby
memoize def user
  User.find(some_id)
end
```

Also, you're getting additional features, like conditions of memoization, time-to-live,
handy memoized values flushing, etc.

## Alt?

It's a fork of [Memery gem](https://github.com/tycooon/memery).
Original Memery uses `prepend Module.new` with memoized methods, not touching original ones.
This approach has advantages, but also has problems, see discussion here:
<https://github.com/tycooon/memery/pull/1>

So, this fork uses `UnboundMethod` as I've suggested in the PR above.

## Difference with other gems

Such gems like [Memoist](https://github.com/matthewrudy/memoist) override methods.
So, if you want to memoize a method in a child class with the same named memoized method
in a parent class — you have to use something like awkward `identifier: ` argument.
This gem allows you to just memoize methods when you want to.

Note how both method's return values are cached separately and don't interfere with each other.

The other key difference is that it doesn't change method's arguments
(no extra param like `reload`). If you need to get unmemoize result of method —
just call the `#clear_memery_cache!` method with needed memoized method names:

```ruby
a.clear_memery_cache! :foo, :bar
```

Without arguments, `#clear_memery_cache!` will clear the whole instance's cache.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'alt_memery'
```

And then execute:

```shell
bundle install
```

Or install it yourself as:

```shell
gem install alt_memery
```

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

Methods with arguments are supported and the memoization will be done based on arguments
using an internal hash. So this will work as expected:

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

If you want to see memoized method source:

```ruby
class A
  include Memery

  memoize def call
    puts "calculating"
    42
  end
end

# This will print memoization logic, don't use it.
# The same for `show-source A#call` in `pry`.
puts A.instance_method(:call).source

# And this will work correctly.
puts A.memoized_methods[:call].source
```

But if a memoized method has been defined in an included module — it'd be a bit harder:

```ruby
module A
  include Memery

  memoize def foo
    'source'
  end
end

module B
  include Memery
  include A

  memoize def foo
    "Get this #{super}!"
  end
end

class C
  include B
end

puts C.instance_method(:foo).owner.memoized_methods[:foo].source
# memoize def foo
#   "Get this #{super}!"
# end

puts C.instance_method(:foo).super_method.owner.memoized_methods[:foo].source
# memoize def foo
#   'source'
# end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/AlexWayfer/alt_memery>.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
