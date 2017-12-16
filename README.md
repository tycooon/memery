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

# Text will be printed only once.
```

## Features
Mememaster is very similar to [Memoist](https://github.com/matthewrudy/memoist). The difference is that it doesn't override methods, instead it uses Ruby 2 `Module.prepend` feature. This approach is cleaner and it allows subclasses' methods to work properly: by default, if you redefine a memoized method in a subclass, it's not memoized by default, but you can memoize it normally (without using awkward `identifier: ` argument) and it will just work.

The other key difference is that it doesn't change method's signature (no extra `reload` param). If you need unmemoized version of method, just make it like this:

```ruby
memoize def users
  get_users
end

def get_users
  # ...
end
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
