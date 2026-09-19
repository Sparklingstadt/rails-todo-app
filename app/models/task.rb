class Task < ApplicationRecord
  enum :priority, { low: 0, normal: 1, high: 2 }, default: :normal, validate: true
  normalizes :title, with: ->(title) { title.strip }

  validates :title, presence: true, length: { maximum: 120 }
  validates :description, length: { maximum: 2_000 }
  validates :completed, inclusion: { in: [ true, false ] }
  validate :due_on_must_be_a_date

  scope :incomplete, -> { where(completed: false) }
  scope :complete, -> { where(completed: true) }
  scope :ordered, -> { order(completed: :asc, priority: :desc).order(Arel.sql("due_on IS NULL"), :due_on, created_at: :desc, id: :desc) }

  def overdue?
    !completed? && due_on.present? && due_on < Date.current
  end

  private

  def due_on_must_be_a_date
    errors.add(:due_on, :invalid) if due_on_before_type_cast.present? && due_on.nil?
  end
end
