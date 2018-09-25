# frozen_string_literal: true

shared_context 'fully operational' do |account_class = Account|
  context 'with valid transfer' do
    include_context 'valid transfer', account_class
  end

  context 'with invalid transfer' do
    include_context 'invalid transfer with exception', account_class
  end

  context 'with conflicting parallel operations' do
    include_context 'conflicting parallel operations', account_class
  end

  context 'with conflicting parallel operations' do
    include_context 'conflicting parallel operations, order matters', account_class
  end

  context 'with non conflicting parallel operations' do
    include_context 'handles deadlocks', account_class
  end
end
