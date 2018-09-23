# frozen_string_literal: true

describe TransferBalance::OptLockV0 do
  context 'with valid transfer' do
    include_context 'valid transfer', OptLockAccount
  end

  context 'with invalid transfer' do
    include_context 'invalid transfer with exception', OptLockAccount
  end

  context 'with conflicting parallel operations' do
    include_context 'conflicting parallel operations', OptLockAccount
  end
end
