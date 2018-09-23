# frozen_string_literal: true

describe TransferBalance::V1 do
  context 'with valid transfer' do
    include_context 'valid transfer'
  end

  context 'with invalid transfer' do
    include_context 'invalid transfer'
  end
end
