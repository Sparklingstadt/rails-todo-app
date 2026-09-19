require "test_helper"

class TasksHelperTest < ActionView::TestCase
  test "labels tasks without a deadline" do
    assert_equal "期限なし", task_due_label(Task.new)
  end

  test "labels deadlines today" do
    travel_to Time.zone.local(2026, 9, 20, 12) do
      assert_equal "今日まで", task_due_label(Task.new(due_on: "2026-09-20"))
    end
  end

  test "labels tomorrow across the year boundary" do
    travel_to Time.zone.local(2026, 12, 31, 12) do
      assert_equal "明日まで", task_due_label(Task.new(due_on: "2027-01-01"))
    end
  end

  test "formats past and later deadlines with their year" do
    travel_to Time.zone.local(2026, 9, 20, 12) do
      assert_equal "2025/12/31", task_due_label(Task.new(due_on: "2025-12-31"))
      assert_equal "2027/1/2", task_due_label(Task.new(due_on: "2027-01-02"))
    end
  end

  test "changes relative labels at midnight in Tokyo rather than UTC" do
    task = Task.new(due_on: "2026-10-01")

    travel_to Time.utc(2026, 9, 30, 14, 59) do
      assert_equal "明日まで", task_due_label(task)
    end
    travel_to Time.utc(2026, 9, 30, 15, 0) do
      assert_equal "今日まで", task_due_label(task)
    end
  end
end
