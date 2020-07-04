# frozen_string_literal: true

# rubocop:disable Style/MutableConstant
CALLS = []
B_CALLS = []
# rubocop:enable Style/MutableConstant

class A
  include Memery

  attr_accessor :environment

  memoize def m
    m_private
  end

  def not_memoized; end

  memoize def m_nil
    m_protected
  end

  memoize def m_args(first, second)
    CALLS << [first, second]
    [first, second]
  end

  memoize def m_kwargs(first, second: 42)
    CALLS << [first, second]
    [first, second]
  end

  memoize def m_double_splat(first, **kwargs)
    CALLS << [first, kwargs]
    [first, kwargs]
  end

  def m_condition
    CALLS << __method__
    __method__
  end

  memoize :m_condition, condition: -> { environment == 'production' }

  def m_ttl(first, second)
    CALLS << [first, second]
    [first, second]
  end

  memoize :m_ttl, ttl: 3

  protected

  memoize def m_protected
    CALLS << nil
    nil
  end

  private

  memoize def m_private
    CALLS << :m
    :m
  end
end

class B < A
  memoize def m_args(first, second)
    B_CALLS << [first, second]
    super(1, 2)
    100
  end
end

module M
  include Memery

  memoize def m
    CALLS << :m
    :m
  end

  def not_memoized; end

  private

  memoize def m_private; end
end

class C
  include M

  memoize def m_class
    CALLS << __method__
    __method__
  end
end

class D
  class << self
    include Memery

    memoize def m_args(first, second)
      CALLS << [first, second]
      [first, second]
    end
  end
end

class E
  extend Forwardable
  def_delegator :a, :m

  include Memery

  memoize def a
    A.new
  end
end

class F
  include Memery

  def m; end
end

class G
  include Memery

  def self.macro(name)
    define_method(:macro_received) { name }
  end

  macro memoize def g; end
end

RSpec.describe Memery do
  subject(:a) { A.new }

  before do
    CALLS.clear
    B_CALLS.clear
  end

  shared_examples 'correct values and calls' do
    describe 'values' do
      subject { values }

      it { is_expected.to eq expected_values }
    end

    describe 'calls' do
      subject { CALLS }

      before do
        values
      end

      it { is_expected.to eq expected_calls }
    end
  end

  context 'when methods without args' do
    let(:values) { [a.m, a.m_nil, a.m, a.m_nil] }

    let(:expected_values) { [:m, nil, :m, nil] }
    let(:expected_calls) { [:m, nil] }

    include_examples 'correct values and calls'
  end

  describe 'flushing cache' do
    context 'without arguments' do
      def double_a_m_call
        [a.m, a.m]
      end

      before do
        values
        a.clear_memery_cache!
        values.concat double_a_m_call
      end

      let(:values) { double_a_m_call }

      let(:expected_values) { %i[m m m m] }
      let(:expected_calls) { %i[m m] }

      include_examples 'correct values and calls'
    end

    context 'with specific methods as arguments' do
      def methods_calls
        [a.m, a.m, a.m_args(1, 2), a.m_args(1, 2), a.m_nil, a.m_nil]
      end

      before do
        values
        a.clear_memery_cache! :m, :m_private, :m_nil, :m_protected, :m_kwargs
        values.concat methods_calls
      end

      let(:values) { methods_calls }

      let(:expected_values) { [:m, :m, [1, 2], [1, 2], nil, nil] * 2 }
      let(:expected_calls) { [:m, [1, 2], nil, :m, nil] }

      include_examples 'correct values and calls'
    end
  end

  context 'when method with args' do
    let(:values) { [a.m_args(1, 1), a.m_args(1, 1), a.m_args(1, 2)] }

    let(:expected_values) { [[1, 1], [1, 1], [1, 2]] }
    let(:expected_calls) { [[1, 1], [1, 2]] }

    include_examples 'correct values and calls'

    context 'when receiving Hash-like object' do
      let(:object_class) do
        Struct.new(:first_name, :last_name) do
          # For example, Sequel models have such implicit coercion,
          # which conflicts with `**kwargs`.
          alias_method :to_hash, :to_h
        end
      end

      let(:object) { object_class.new('John', 'Wick') }

      let(:values) do
        [a.m_args(1, object), a.m_args(1, object), a.m_args(1, 2)]
      end

      let(:expected_values) { [[1, object], [1, object], [1, 2]] }
      let(:expected_calls) { [[1, object], [1, 2]] }

      include_examples 'correct values and calls'
    end
  end

  context 'when method with keyword args' do
    let(:values) do
      [
        a.m_kwargs(1, second: 2),
        a.m_kwargs(1, second: 2),
        a.m_kwargs(1, second: 3)
      ]
    end

    let(:expected_values) { [[1, 2], [1, 2], [1, 3]] }
    let(:expected_calls) { [[1, 2], [1, 3]] }

    include_examples 'correct values and calls'
  end

  context 'when method with double splat argument' do
    let(:values) do
      [
        a.m_double_splat(1, second: 2),
        a.m_double_splat(1, second: 2),
        a.m_double_splat(1, second: 3)
      ]
    end

    let(:expected_values) do
      [[1, { second: 2 }], [1, { second: 2 }], [1, { second: 3 }]]
    end

    let(:expected_calls) do
      [[1, { second: 2 }], [1, { second: 3 }]]
    end

    include_examples 'correct values and calls'
  end

  context 'when calling method with block' do
    let(:values) { [] }

    let(:expected_values) { [[1, 1], [1, 1]] }
    let(:expected_calls) { [[1, 1], [1, 1]] }

    before do
      values << a.m_args(1, 1) {}
      values << a.m_args(1, 1) {}
    end

    include_examples 'correct values and calls'
  end

  context 'when calling private method' do
    specify do
      expect { a.m_private }.to raise_error(NoMethodError, /private method/)
    end
  end

  context 'when calling protected method' do
    specify do
      expect { a.m_protected }.to raise_error(NoMethodError, /protected method/)
    end
  end

  describe 'chaining macros' do
    subject(:g) { G.new }

    specify do
      expect(g.macro_received).to eq :g
    end
  end

  context 'when class is inherited' do
    subject(:b) { B.new }

    before do
      values
    end

    let(:values) do
      [b.m_args(1, 1), b.m_args(1, 2), b.m_args(1, 1)]
    end

    let(:expected_values) { [100, 100, 100] }
    let(:expected_calls) { [[1, 2]] }

    include_examples 'correct values and calls'

    describe 'B calls' do
      subject { B_CALLS }

      it { is_expected.to eq [[1, 1], [1, 2]] }
    end
  end

  context 'when memoization from included module' do
    subject(:c) { C.new }

    let(:values) { [c.m, c.m, c.m] }

    let(:expected_values) { %i[m m m] }
    let(:expected_calls) { %i[m] }

    include_examples 'correct values and calls'

    context 'when memoization in class' do
      let(:values) { [c.m_class, c.m_class, c.m_class] }

      let(:expected_values) { %i[m_class m_class m_class] }
      let(:expected_calls) { %i[m_class] }

      include_examples 'correct values and calls'
    end
  end

  context 'when module with `self.included` method defined' do
    subject(:c) { C.new }

    before { C.include(some_mixin) }

    let(:some_mixin) do
      Module.new do
        extend ActiveSupport::Concern
        include Memery

        included do
          attr_accessor :a
        end
      end
    end

    it 'does not override existing method' do
      c.a = 15
      expect(c.a).to eq(15)
    end
  end

  context 'with class method with args' do
    subject(:d) { D }

    before do
      ## HACK: Memoizing in class cache globally, between tests
      ## Delete it with `stub_const`
      d.clear_memery_cache!
    end

    let(:values) { [d.m_args(1, 1), d.m_args(1, 1), d.m_args(1, 2)] }

    let(:expected_values) { [[1, 1], [1, 1], [1, 2]] }
    let(:expected_calls) { [[1, 1], [1, 2]] }

    include_examples 'correct values and calls'
  end

  context 'when method does not exist' do
    subject(:klass) do
      Class.new do
        include Memery
        memoize :foo
      end
    end

    specify do
      expect { klass }.to raise_error(
        ArgumentError, /Method foo is not defined/
      )
    end
  end

  context 'when method is forwarded' do
    subject(:e) { E.new }

    let(:values) { [e.m, e.m, e.m] }

    let(:expected_values) { %i[m m m] }
    let(:expected_calls) { %i[m] }

    include_examples 'correct values and calls'
  end

  describe ':condition option' do
    before do
      a.environment = environment
    end

    context 'when returns true' do
      let(:environment) { 'production' }

      let(:values) { [a.m_condition, a.m_nil, a.m_condition, a.m_nil] }

      let(:expected_values) { [:m_condition, nil, :m_condition, nil] }
      let(:expected_calls) { [:m_condition, nil] }

      include_examples 'correct values and calls'
    end

    context 'when returns false' do
      let(:environment) { 'development' }

      let(:values) { [a.m_condition, a.m_nil, a.m_condition, a.m_nil] }

      let(:expected_values) { [:m_condition, nil, :m_condition, nil] }
      let(:expected_calls) { [:m_condition, nil, :m_condition] }

      include_examples 'correct values and calls'
    end
  end

  describe ':ttl option' do
    def calculate_values
      [a.m_ttl(1, 1), a.m_ttl(1, 1), a.m_ttl(1, 2)]
    end

    let(:values) { calculate_values }

    let(:expected_values) { [[1, 1], [1, 1], [1, 2]] }
    let(:expected_calls) { [[1, 1], [1, 2]] }

    include_examples 'correct values and calls'

    context 'when ttl has expired' do
      before do
        values

        allow(Process).to(
          receive(:clock_gettime).with(Process::CLOCK_MONOTONIC)
            .and_wrap_original { |m, *args| m.call(*args) + 5 }
        )

        calculate_values
      end

      let(:expected_calls) { [[1, 1], [1, 2], [1, 1], [1, 2]] }

      include_examples 'correct values and calls'
    end
  end

  describe '.memoized?' do
    subject { object.memoized?(method_name) }

    context 'when class without memoized methods' do
      let(:object) { F }
      let(:method_name) { :m }

      it { is_expected.to be false }
    end

    shared_examples 'works correctly' do
      context 'with public memoized method' do
        let(:method_name) { :m }

        it { is_expected.to be true }
      end

      context 'with private memoized method' do
        let(:method_name) { :m_private }

        it { is_expected.to be true }
      end

      context 'with non-memoized method' do
        let(:method_name) { :not_memoized }

        it { is_expected.to be false }
      end

      context 'with standard class method' do
        let(:method_name) { :constants }

        it { is_expected.to be false }
      end

      context 'with standard instance method' do
        let(:method_name) { :to_s }

        it { is_expected.to be false }
      end
    end

    context 'with class' do
      let(:object) { A }

      include_examples 'works correctly'
    end

    context 'with module' do
      let(:object) { M }

      include_examples 'works correctly'
    end
  end
end
