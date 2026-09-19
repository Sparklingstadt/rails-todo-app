require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "requires a title and normalizes whitespace" do
    task = Task.new(title: "  Railsを学ぶ  ")
    assert task.valid?
    assert_equal "Railsを学ぶ", task.title
    task.title = "　   "
    assert_not task.valid?
    assert task.errors.of_kind?(:title, :blank)
  end

  test "enforces title and description length limits" do
    task = Task.new(title: "あ" * 120, description: "あ" * 2_000)
    assert task.valid?
    task.title += "あ"
    task.description += "あ"
    assert_not task.valid?
    assert task.errors.of_kind?(:title, :too_long)
    assert task.errors.of_kind?(:description, :too_long)
  end

  test "validates priority and completed state" do
    task = Task.new(title: "テスト", priority: "unknown", completed: nil)
    assert_not task.valid?
    assert task.errors.of_kind?(:priority, :inclusion)
    assert task.errors.of_kind?(:completed, :inclusion)
  end

  test "accepts optional deadline but rejects invalid dates" do
    task = Task.new(title: "テスト", due_on: "")
    assert task.valid?
    task.due_on = "2026-99-99"
    assert_not task.valid?
    assert task.errors.of_kind?(:due_on, :invalid)
  end

  test "marks only incomplete tasks before today overdue in Tokyo time" do
    travel_to Time.zone.local(2026, 9, 20, 0, 30) do
      task = Task.new(title: "テスト", due_on: Date.yesterday)
      assert task.overdue?
      task.completed = true
      assert_not task.overdue?
      task.completed = false
      task.due_on = Date.current
      assert_not task.overdue?
    end
  end

  test "orders incomplete tasks by priority then deadline with undated tasks last" do
    Task.delete_all
    undated = Task.create!(title: "期限なし", priority: :high)
    later = Task.create!(title: "明日", priority: :high, due_on: Date.tomorrow)
    first = Task.create!(title: "今日", priority: :high, due_on: Date.current)
    low = Task.create!(title: "低", priority: :low, due_on: Date.yesterday)
    complete = Task.create!(title: "完了", priority: :high, completed: true)
    assert_equal [ first, later, undated, low, complete ], Task.ordered.to_a
  end

  test "database rejects blank titles even when validations are bypassed" do
    assert_raises(ActiveRecord::StatementInvalid) do
      tasks(:learn).update_columns(title: " ")
    end
  end

  test "persists normalized titles and defaults without optional fields" do
    task = Task.create!(title: "\t 最初のタスク \n").reload

    assert_equal "最初のタスク", task.title
    assert_equal "normal", task.priority
    assert_equal false, task.completed
    assert_nil task.description
    assert_nil task.due_on
  end

  test "rejects nonexistent calendar dates and persists leap day" do
    task = Task.new(title: "日付を確認", due_on: "2026-02-29")
    assert_not task.valid?
    assert task.errors.of_kind?(:due_on, :invalid)

    task.due_on = "2028-02-29"
    task.save!
    assert_equal Date.new(2028, 2, 29), task.reload.due_on
  end

  test "completion scopes move records between mutually exclusive lists" do
    task = tasks(:learn)
    assert_includes Task.incomplete, task
    assert_not_includes Task.complete, task

    task.update!(completed: true)
    assert_includes Task.complete, task.reload
    assert_not_includes Task.incomplete, task

    task.update!(completed: false)
    assert_includes Task.incomplete, task.reload
    assert_not_includes Task.complete, task
  end

  test "undated and future tasks are not overdue" do
    travel_to Time.zone.local(2026, 9, 20, 12) do
      task = Task.new(title: "期限を確認")
      assert_not task.overdue?

      task.due_on = Date.tomorrow
      assert_not task.overdue?
    end
  end

  test "breaks priority and deadline ties by creation time then id" do
    timestamp = Time.zone.local(2026, 9, 20, 12)
    older = Task.create!(title: "前のタスク", created_at: timestamp - 1.minute)
    newer = Task.create!(title: "新しいタスク", created_at: timestamp)
    same_time = Task.create!(title: "同時刻のタスク", created_at: timestamp)

    assert_equal [ same_time.id, newer.id, older.id ],
      Task.where(id: [ older.id, newer.id, same_time.id ]).ordered.pluck(:id)
  end

  test "database protects priority completion and title length without validations" do
    task = tasks(:learn)

    [ { priority: 3 }, { completed: nil }, { title: nil }, { title: "あ" * 121 } ].each do |attributes|
      assert_raises(ActiveRecord::StatementInvalid, attributes.inspect) do
        task.update_columns(attributes)
      end
      task.reload
    end
  end
end
