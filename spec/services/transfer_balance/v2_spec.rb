# frozen_string_literal: true

describe TransferBalance::V2 do
  context 'with valid transfer' do
    include_context 'valid transfer'
  end

  context 'with invalid transfer' do
    include_context 'invalid transfer with exception'
  end

  context 'with conflicting parallel operations' do
    include_context 'conflicting parallel operations'
  end
end
