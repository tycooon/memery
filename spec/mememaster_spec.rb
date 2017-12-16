# frozen_string_literal: true

# rubocop:disable Style/MutableConstant

CALLS = []
B_CALLS = []

class A
  extend Mememaster

  memoize def m
    CALLS << :m
    :m
  end

  memoize def m_nil
    CALLS << nil
    nil
  end

  memoize def m_args(x, y)
    CALLS << [x, y]
    [x, y]
  end
end

class B < A
  memoize def m_args(x, y)
    B_CALLS << [x, y]
    super(1, 2)
    100
  end
end

RSpec.describe Mememaster do
  before { CALLS.clear }
  before { B_CALLS.clear }

  subject(:a) { A.new }

  context "methods without args" do
    specify do
      values = [ a.m, a.m_nil, a.m, a.m_nil ]
      expect(values).to eq([:m, nil, :m, nil])
      expect(CALLS).to eq([:m, nil])
    end
  end

  context "method with args" do
    specify do
      values = [ a.m_args(1, 1), a.m_args(1, 1), a.m_args(1, 2) ]
      expect(values).to eq([[1, 1], [1, 1], [1, 2]])
      expect(CALLS).to eq([[1, 1], [1, 2]])
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
end
