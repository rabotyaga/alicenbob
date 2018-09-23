# frozen_string_literal: true

describe TransferBalance::OptLockV1 do
  context 'with valid transfer' do
    include_context 'valid transfer', OptLockAccount
  end

  context 'with invalid transfer' do
    include_context 'invalid transfer with exception', OptLockAccount
  end

  context 'with conflicting parallel operations' do
    include_context 'conflicting parallel operations', OptLockAccount
  end

  context 'with conflicting parallel operations' do
    include_context 'conflicting parallel operations, order matters', OptLockAccount
  end

  context 'with non conflicting parallel operations' do
    include_context 'handles deadlocks', OptLockAccount
  end
end
