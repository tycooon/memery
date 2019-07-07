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

  memoize def m_nil
    m_protected
  end

  memoize def m_args(x, y)
    CALLS << [x, y]
    [x, y]
  end

  def m_condition
    CALLS << __method__
    __method__
  end

  memoize :m_condition, condition: -> { environment == "production" }

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
end

class C
  include M
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
  end

  context "calling method with block" do
    specify do
      values = []
      values << a.m_args(1, 1) {}
      values << a.m_args(1, 1) {}

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
end
