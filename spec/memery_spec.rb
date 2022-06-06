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

  memoize def m_args(x, y)
    CALLS << [x, y]
    [x, y]
  end

  memoize def m_kwargs(x, y: 42)
    CALLS << [x, y]
    [x, y]
  end

  memoize def m_double_splat(x, **kwargs)
    CALLS << [x, kwargs]
    [x, kwargs]
  end

  def m_condition
    CALLS << __method__
    __method__
  end

  memoize :m_condition, condition: -> { environment == "production" }

  def m_condition_bool_true
    CALLS << __method__
    __method__
  end

  memoize :m_condition_bool_true, condition: true

  def m_condition_bool_false
    CALLS << __method__
    __method__
  end

  memoize :m_condition_bool_false, condition: false

  def m_ttl(x, y)
    CALLS << [x, y]
    [x, y]
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
  memoize def m_args(x, y)
    B_CALLS << [x, y]
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

    memoize def m_args(x, y)
      CALLS << [x, y]
      [x, y]
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

  before { CALLS.clear }
  before { B_CALLS.clear }

  context "methods without args" do
    specify do
      values = [ a.m, a.m_nil, a.m, a.m_nil ]
      expect(values).to eq([:m, nil, :m, nil])
      expect(CALLS).to eq([:m, nil])
    end
  end

  context "flushing cache" do
    specify do
      values = [ a.m, a.m ]
      a.clear_memery_cache!
      values << a.m
      expect(values).to eq([:m, :m, :m])
      expect(CALLS).to eq([:m, :m])
    end
  end

  context "method with args" do
    specify do
      values = [ a.m_args(1, 1), a.m_args(1, 1), a.m_args(1, 2) ]
      expect(values).to eq([[1, 1], [1, 1], [1, 2]])
      expect(CALLS).to eq([[1, 1], [1, 2]])
    end

    context "receiving Hash-like object" do
      let(:object_class) do
        Struct.new(:first_name, :last_name) do
          # For example, Sequel models have such implicit coercion,
          # which conflicts with `**kwargs`.
          alias_method :to_hash, :to_h
        end
      end

      let(:object) { object_class.new("John", "Wick") }

      specify do
        values = [ a.m_args(1, object), a.m_args(1, object), a.m_args(1, 2) ]
        expect(values).to eq([[1, object], [1, object], [1, 2]])
        expect(CALLS).to eq([[1, object], [1, 2]])
      end
    end
  end

  context "method with keyword args" do
    specify do
      values = [ a.m_kwargs(1, y: 2), a.m_kwargs(1, y: 2), a.m_kwargs(1, y: 3) ]
      expect(values).to eq([[1, 2], [1, 2], [1, 3]])
      expect(CALLS).to eq([[1, 2], [1, 3]])
    end
  end

  context "method with double splat argument" do
    specify do
      values = [ a.m_double_splat(1, y: 2), a.m_double_splat(1, y: 2), a.m_double_splat(1, y: 3) ]
      expect(values).to eq([[1, { y: 2 }], [1, { y: 2 }], [1, { y: 3 }]])
      expect(CALLS).to eq([[1, { y: 2 }], [1, { y: 3 }]])
    end
  end

  context "calling method with block" do
    specify do
      values = []
      values << a.m_args(1, 1) { nil }
      values << a.m_args(1, 1) { nil }

      expect(values).to eq([[1, 1], [1, 1]])
      expect(CALLS).to eq([[1, 1], [1, 1]])
    end
  end

  context "calling private method" do
    specify do
      expect { a.m_private }.to raise_error(NoMethodError, /private method/)
    end
  end

  context "calling protected method" do
    specify do
      expect { a.m_protected }.to raise_error(NoMethodError, /protected method/)
    end
  end

  context "Chaining macros" do
    subject(:g) { G.new }

    specify do
      expect(g.macro_received).to eq :g
    end
  end

  context "inherited class" do
    subject(:b) { B.new }

    specify do
      values = [ b.m_args(1, 1), b.m_args(1, 2), b.m_args(1, 1) ]
      expect(values).to eq([100, 100, 100])
      expect(CALLS).to eq([[1, 2]])
      expect(B_CALLS).to eq([[1, 1], [1, 2]])
    end
  end

  context "module" do
    subject(:c) { C.new }

    specify do
      values = [c.m, c.m, c.m]
      expect(values).to eq([:m, :m, :m])
      expect(CALLS).to eq([:m])
    end

    context "memoization in class" do
      specify do
        values = [c.m_class, c.m_class, c.m_class]
        expect(values).to eq([:m_class, :m_class, :m_class])
        expect(CALLS).to eq([:m_class])
      end
    end
  end

  context "module with self.included method defined" do
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

    it "doesn't override existing method" do
      c.a = 15
      expect(c.a).to eq(15)
    end
  end

  context "class method with args" do
    subject(:d) { D }

    specify do
      values = [ d.m_args(1, 1), d.m_args(1, 1), d.m_args(1, 2) ]
      expect(values).to eq([[1, 1], [1, 1], [1, 2]])
      expect(CALLS).to eq([[1, 1], [1, 2]])
    end
  end

  context "memoizing inexistent method" do
    subject(:klass) do
      Class.new do
        include Memery
        memoize :foo
      end
    end

    specify do
      expect { klass }.to raise_error(ArgumentError, /Method foo is not defined/)
    end
  end

  context "Forwardable" do
    subject(:e) { E.new }

    specify do
      values = [e.m, e.m, e.m]
      expect(values).to eq([:m, :m, :m])
      expect(CALLS).to eq([:m])
    end
  end

  describe ":condition option" do
    before do
      a.environment = environment
    end

    context "returns true" do
      let(:environment) { "production" }

      specify do
        values = [ a.m_condition, a.m_nil, a.m_condition, a.m_nil ]
        expect(values).to eq([:m_condition, nil, :m_condition, nil])
        expect(CALLS).to eq([:m_condition, nil])
      end
    end

    context "returns false" do
      let(:environment) { "development" }

      specify do
        values = [ a.m_condition, a.m_nil, a.m_condition, a.m_nil ]
        expect(values).to eq([:m_condition, nil, :m_condition, nil])
        expect(CALLS).to eq([:m_condition, nil, :m_condition])
      end
    end

    context "bool is true" do
      let(:environment) { "development" }

      specify do
        values = [ a.m_condition_bool_true, a.m_nil, a.m_condition_bool_true, a.m_nil ]
        expect(values).to eq([:m_condition_bool_true, nil, :m_condition_bool_true, nil])
        expect(CALLS).to eq([:m_condition_bool_true, nil])
      end
    end

    context "bool is false" do
      let(:environment) { "development" }

      specify do
        values = [ a.m_condition_bool_false, a.m_nil, a.m_condition_bool_false, a.m_nil ]
        expect(values).to eq([:m_condition_bool_false, nil, :m_condition_bool_false, nil])
        expect(CALLS).to eq([:m_condition_bool_false, nil, :m_condition_bool_false])
      end
    end
  end

  describe ":ttl option" do
    specify do
      values = [ a.m_ttl(1, 1), a.m_ttl(1, 1), a.m_ttl(1, 2) ]
      expect(values).to eq([[1, 1], [1, 1], [1, 2]])
      expect(CALLS).to eq([[1, 1], [1, 2]])

      allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC)
        .and_wrap_original { |m, *args| m.call(*args) + 5 }

      values = [ a.m_ttl(1, 1), a.m_ttl(1, 1), a.m_ttl(1, 2) ]
      expect(values).to eq([[1, 1], [1, 1], [1, 2]])
      expect(CALLS).to eq([[1, 1], [1, 2], [1, 1], [1, 2]])
    end

    context "returns false" do
      let(:environment) { "development" }

      specify do
        values = [ a.m_condition, a.m_nil, a.m_condition, a.m_nil ]
        expect(values).to eq([:m_condition, nil, :m_condition, nil])
        expect(CALLS).to eq([:m_condition, nil, :m_condition])
      end
    end
  end

  describe ".memoized?" do
    subject { object.memoized?(method_name) }

    context "class without memoized methods" do
      let(:object) { F }
      let(:method_name) { :m }

      it { is_expected.to be false }
    end

    shared_examples "works correctly" do
      context "public memoized method" do
        let(:method_name) { :m }

        it { is_expected.to be true }
      end

      context "private memoized method" do
        let(:method_name) { :m_private }

        it { is_expected.to be true }
      end

      context "non-memoized method" do
        let(:method_name) { :not_memoized }

        it { is_expected.to be false }
      end

      context "standard class method" do
        let(:method_name) { :constants }

        it { is_expected.to be false }
      end

      context "standard instance method" do
        let(:method_name) { :to_s }

        it { is_expected.to be false }
      end
    end

    context "class" do
      let(:object) { A }

      include_examples "works correctly"
    end

    context "module" do
      let(:object) { M }

      include_examples "works correctly"
    end
  end
end
