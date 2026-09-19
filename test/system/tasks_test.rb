require "application_system_test_case"

class TasksTest < ApplicationSystemTestCase
  test "creates edits completes reopens and deletes a task through the browser" do
    visit root_url
    fill_in "タスク名", with: "ブラウザで確認する"
    fill_in "メモ", with: "作成から削除まで"
    select "高", from: "優先度"
    click_button "タスクを追加"
    assert_text "タスクを追加しました。"
    visit root_url
    assert_link "ブラウザで確認する"
    click_link "ブラウザで確認するを編集"
    fill_in "タスク名", with: "確認できたタスク"
    click_button "変更を保存"
    assert_text "タスクを更新しました。"
    click_button "確認できたタスクを完了にする"
    assert_text "タスクを完了しました。"
    find(".filter-tabs a[href='/?status=complete']").click
    assert_current_path root_path(status: "complete")
    assert_link "確認できたタスク"
    click_button "確認できたタスクを未完了に戻す"
    assert_text "タスクを未完了に戻しました。"
    assert_no_link "確認できたタスク"
    visit root_url
    click_link "確認できたタスクを編集"
    dismiss_confirm { click_button "タスクを削除" }
    assert_button "タスクを削除"
    accept_confirm { click_button "タスクを削除" }
    assert_text "タスクを削除しました。"
    assert_no_link "確認できたタスク"
  end

  test "shows server validation feedback for whitespace-only title" do
    visit root_url
    fill_in "タスク名", with: "   "
    fill_in "メモ", with: "入力を保持"
    click_button "タスクを追加"
    assert_text "タスク名を入力してください。"
    assert_field "メモ", with: "入力を保持"
  end

  test "mobile layout fits viewport and can add a task" do
    page.current_window.resize_to(390, 844)
    visit root_url
    assert_equal false, page.evaluate_script("document.documentElement.scrollWidth > window.innerWidth")
    click_link "タスクを追加"
    assert_current_path(root_path) { |uri| uri.fragment == "new-task" }
    fill_in "タスク名", with: "スマートフォンから追加"
    click_button "タスクを追加"
    assert_text "タスクを追加しました。"
    assert_link "スマートフォンから追加"
    assert_equal false, page.evaluate_script("document.documentElement.scrollWidth > window.innerWidth")
  end
end
