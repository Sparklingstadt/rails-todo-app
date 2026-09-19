require "application_system_test_case"

class TaskManagementTest < ApplicationSystemTestCase
  test "persists every field from the dedicated new form after reloading" do
    visit new_task_url
    fill_in "タスク名", with: "応募書類を準備する"
    fill_in "メモ", with: "職務経歴書を見直す\n成果を具体的に書く"
    fill_in "期限", with: Date.new(2026, 10, 1)
    select "低", from: "優先度"
    click_button "タスクを追加"
    assert_text "タスクを追加しました。"

    page.refresh
    click_link "応募書類を準備するを編集", exact: true
    assert_field "タスク名", with: "応募書類を準備する"
    assert_field "メモ", with: "職務経歴書を見直す\n成果を具体的に書く"
    assert_field "期限", with: "2026-10-01"
    assert_select "優先度", selected: "低"

    fill_in "メモ", with: "更新したメモ"
    fill_in "期限", with: ""
    select "高", from: "優先度"
    click_button "変更を保存"
    assert_text "タスクを更新しました。"
    page.refresh
    click_link "応募書類を準備するを編集", exact: true
    assert_field "メモ", with: "更新したメモ"
    assert_field "期限", with: ""
    assert_select "優先度", selected: "高"
  end

  test "recovers from invalid edits while preserving entered fields" do
    task = tasks(:learn)
    original_attributes = task.attributes.slice("title", "description", "due_on", "priority")
    visit edit_task_url(task)
    fill_in "タスク名", with: "   "
    fill_in "メモ", with: "エラーが出ても残したいメモ"
    fill_in "期限", with: Date.new(2026, 10, 2)
    select "低", from: "優先度"
    click_button "変更を保存"

    assert_selector "[role=alert]", text: "タスク名を入力してください。"
    assert_field "メモ", with: "エラーが出ても残したいメモ"
    assert_field "期限", with: "2026-10-02"
    assert_select "優先度", selected: "低"
    assert_equal original_attributes, task.reload.attributes.slice("title", "description", "due_on", "priority")

    fill_in "タスク名", with: "入力を修正したタスク"
    click_button "変更を保存"
    assert_text "タスクを更新しました。"
    page.refresh
    click_link "入力を修正したタスクを編集", exact: true
    assert_field "メモ", with: "エラーが出ても残したいメモ"
    assert_field "期限", with: "2026-10-02"
    assert_select "優先度", selected: "低"
  end

  test "keeps global progress consistent when completing tasks in a filtered list" do
    task = tasks(:learn)
    visit root_url
    assert_selector "progress[value='50']"

    find(".filter-tabs a[href='/?status=incomplete']").click
    assert_current_path root_path(status: "incomplete")
    assert_selector ".task-row", count: 1
    assert_no_link tasks(:finished).title, exact: true
    assert_selector "progress[value='50']"
    click_button "#{task.title}を完了にする", exact: true
    assert_text "タスクを完了しました。"
    assert_current_path root_path(status: "incomplete")
    assert_text "未完了のタスクはありません"
    assert_selector "progress[value='100']"
    assert_selector ".overview-count", text: /\A0\s*未完了\z/
    assert_selector ".overview-count", text: /\A2\s*完了\z/

    page.refresh
    assert_no_selector ".task-row"
    assert_selector "progress[value='100']"
    find(".filter-tabs a[href='/?status=complete']").click
    assert_current_path root_path(status: "complete")
    assert_selector ".task-row", count: 2
    click_button "#{task.title}を未完了に戻す", exact: true
    assert_text "タスクを未完了に戻しました。"
    assert_no_link task.title, exact: true
    assert_selector "progress[value='50']"
    assert_selector ".task-row", count: 1
  end

  test "canceling deletion preserves data and deleting the last task resets the list" do
    Task.delete_all
    task = Task.create!(title: "最後のタスク", description: "削除前に確認する", completed: true)
    visit edit_task_url(task)
    dismiss_confirm("「最後のタスク」を削除しますか？この操作は取り消せません。") do
      click_button "タスクを削除"
    end

    page.refresh
    assert_field "タスク名", with: "最後のタスク"
    assert_field "メモ", with: "削除前に確認する"
    assert task.reload.completed?
    accept_confirm { click_button "タスクを削除" }
    assert_text "タスクを削除しました。"
    assert_text "最初のタスクを追加しよう"
    assert_selector "progress[value='0']"
    assert_selector ".overview-count", text: /\A0\s*未完了\z/
    assert_selector ".overview-count", text: /\A0\s*完了\z/
    page.refresh
    assert_no_selector ".task-row"
    assert_equal 0, Task.count
  end

  test "adds the first task from the empty state and cancels an unsaved edit" do
    Task.delete_all
    visit root_url
    assert_text "最初のタスクを追加しよう"
    assert_selector "progress[value='0']"
    click_link "タスクを書き出す"
    assert_current_path(root_path) { |uri| uri.fragment == "task_title" }
    fill_in "タスク名", with: "最初の一歩"
    click_button "タスクを追加"
    assert_text "タスクを追加しました。"
    assert_no_text "最初のタスクを追加しよう"
    assert_selector ".task-row", count: 1

    click_link "最初の一歩を編集", exact: true
    fill_in "タスク名", with: "保存しない変更"
    click_link "キャンセル", exact: true
    assert_current_path root_path
    page.refresh
    assert_link "最初の一歩", exact: true
    assert_no_link "保存しない変更", exact: true
  end

  test "renders HTML-looking user input as text in the browser" do
    title = "<script>alert('title')</script>"
    note = "<img src=x onerror=alert('memo')>"
    visit root_url
    fill_in "タスク名", with: title
    fill_in "メモ", with: note
    click_button "タスクを追加"
    assert_text "タスクを追加しました。"
    page.refresh

    within(".task-row", text: title) do
      assert_text title
      assert_text note
      assert_no_selector "script, img", visible: :all
      click_link "#{title}を編集", exact: true
    end
    assert_field "タスク名", with: title
    assert_field "メモ", with: note
  end

  test "mobile form jump preserves a draft and long task text does not overflow" do
    Task.create!(title: "a" * 120, description: "b" * 2_000)
    page.current_window.resize_to(390, 844)
    visit root_url
    assert_no_horizontal_overflow
    fill_in "タスク名", with: "移動しても残る下書き"
    fill_in "メモ", with: "入力中のメモ"
    click_link "タスクを追加", exact: true
    assert_current_path(root_path) { |uri| uri.fragment == "new-task" }
    assert_field "タスク名", with: "移動しても残る下書き"
    assert_field "メモ", with: "入力中のメモ"
    click_button "タスクを追加"
    assert_text "タスクを追加しました。"
    page.refresh
    assert_link "移動しても残る下書き", exact: true
    assert_no_horizontal_overflow
  end

  private

  def assert_no_horizontal_overflow
    assert_equal false, page.evaluate_script("document.documentElement.scrollWidth > window.innerWidth")
  end
end
