class TransactionLogEntry < ActiveRecord::Base
  belongs_to :product, touch: true

  scope :with_cents, -> { where.not(cents: nil) }
  scope :validated, -> { where(action: 'validated') }

  def self.balance(product, user)
    where(product_id: product.id, user_id: user.id).with_cents.sum(:cents)
  end

  def self.sum_balances(user)
    where(user_id: user.id).with_cents.sum(:cents)
  end

  def self.product_balances(user)
    where(user_id: user.id).with_cents.group(:product_id).sum(:cents)
  end

  def self.product_totals
    with_cents.group(:product_id).sum(:cents)
  end

  def self.proposed!(created_at, product, work_id, user_id)
    create!(
      created_at: created_at,
      product: product,
      action: 'proposed',
      work_id: work_id,
      user_id: user_id
    )
  end


  def self.validated!(created_at, product, work_id, user_id, worker_id)
    create!(
      created_at: created_at,
      product: product,
      action: 'validated',
      work_id: work_id,
      user_id: user_id,
      value: worker_id
    ).tap do |entry|
      MinterWorker.perform_async(entry.id)
    end
  end

  def self.voted!(created_at, product, work_id, user_id, vote_count=1)
    create!(
      created_at: created_at,
      product: product,
      action: 'voted',
      work_id: work_id,
      user_id: user_id,
      value: vote_count
    ).tap do |entry|
      MinterWorker.perform_async(entry.id)
    end
  end

  def self.multiplied!(created_at, product, work_id, user_id, multiplier)
    create!(
      created_at: created_at,
      product: product,
      action: 'multiplied',
      work_id: work_id,
      user_id: user_id,
      value: multiplier
    )
  end

  def self.minted!(transaction_id, created_at, product, work_id, user_id, cents, extra=nil)
    create!(
      transaction_id: transaction_id,
      created_at: created_at,
      product: product,
      action: 'minted',
      work_id: work_id,
      user_id: user_id,
      cents: cents,
      extra: extra
    )
  end
end
