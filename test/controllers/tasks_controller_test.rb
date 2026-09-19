require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup { @task = tasks(:learn) }

  test "renders task list and form" do
    get root_url
    assert_response :success
    assert_select "html[lang=ja]"
    assert_select "h1", "マイタスク"
    assert_select ".task-row", count: 2
    assert_select "input[name='task[title]']"
  end

  test "renders empty state" do
    Task.delete_all
    get root_url
    assert_response :success
    assert_select "h3", "最初のタスクを追加しよう"
    assert_select "progress[value='0']"
  end

  test "filters incomplete and complete tasks and ignores unknown filters" do
    get root_url(status: "incomplete")
    assert_select ".task-row", count: 1
    assert_select ".task-title", @task.title
    get root_url(status: "complete")
    assert_select ".task-row", count: 1
    assert_select ".task-title", tasks(:finished).title
    get root_url(status: "unexpected")
    assert_select ".task-row", count: 2
  end

  test "renders new and edit forms" do
    get new_task_url
    assert_response :success
    get edit_task_url(@task)
    assert_response :success
    assert_select "input[value=?]", @task.title
  end

  test "creates a task and persists all permitted fields" do
    assert_difference("Task.count", 1) do
      post tasks_url, params: { task: { title: "新しいタスク", description: "メモ", due_on: "2026-10-01", priority: "low", completed: true } }
    end
    assert_response :see_other
    task = Task.order(:id).last
    assert_equal "メモ", task.description
    assert_equal Date.new(2026, 10, 1), task.due_on
    assert task.low?
    assert_not task.completed?
    follow_redirect!
    assert_select ".task-title", "新しいタスク"
  end

  test "rejects blank title and preserves input with Japanese feedback" do
    assert_no_difference("Task.count") do
      post tasks_url, params: { task: { title: " ", description: "残しておくメモ" } }
    end
    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /タスク名を入力してください/
    assert_select "textarea", "残しておくメモ"
  end

  test "rejects invalid priority and deadline" do
    assert_no_difference("Task.count") do
      post tasks_url, params: { task: { title: "入力不正", priority: "other", due_on: "not-a-date" } }
    end
    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /優先度を正しく/
    assert_select "[role=alert]", text: /期限を正しく/
  end

  test "updates a task" do
    patch task_url(@task), params: { task: { title: "変更後", priority: "low", due_on: "" } }
    assert_response :see_other
    assert_equal "変更後", @task.reload.title
    assert_nil @task.due_on
  end

  test "failed update leaves persisted data intact" do
    original_title = @task.title
    patch task_url(@task), params: { task: { title: "" } }
    assert_response :unprocessable_content
    assert_equal original_title, @task.reload.title
  end

  test "sets completion idempotently and reopens a task" do
    2.times do
      patch completion_task_url(@task, status: "incomplete"), params: { task: { completed: "1", title: "変更しない" } }
      assert_redirected_to root_url(status: "incomplete")
      assert @task.reload.completed?
    end
    assert_equal "Railsのモデルを学ぶ", @task.title
    patch completion_task_url(@task), params: { task: { completed: "0" } }
    assert_not @task.reload.completed?
  end

  test "deletes a task" do
    assert_difference("Task.count", -1) { delete task_url(@task) }
    assert_response :see_other
  end

  test "returns not found for missing task" do
    get edit_task_url(id: 0)
    assert_response :not_found
  end

  test "escapes user input in rendered HTML" do
    @task.update!(title: "<script>alert(1)</script>")
    get root_url
    assert_response :success
    assert_select ".task-title", "<script>alert(1)</script>"
    assert_select ".task-content script", count: 0
  end
end
