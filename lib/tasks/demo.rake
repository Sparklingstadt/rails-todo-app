namespace :demo do
  desc "Add learning examples in development without changing existing tasks"
  task seed: :environment do
    abort "開発環境でのみ実行できます。" unless Rails.env.development?

    [
      { title: "タスクを追加してみる", description: "追加フォームから、自分のやることを書き出してみよう。", priority: :high, due_on: Date.current },
      { title: "Railsのデータの流れを追う", description: "routes → controller → model → view の順にコードを読んでみる。", priority: :normal, due_on: Date.tomorrow },
      { title: "READMEの学習ガイドを読む", description: "小さな変更を加えて、テストで確かめよう。", priority: :low },
      { title: "開発環境を準備する", description: "RailsとSQLiteで、最初の一歩。", priority: :normal, completed: true }
    ].each do |attributes|
      Task.find_or_create_by!(title: attributes.fetch(:title)) { |task| task.assign_attributes(attributes) }
    end
  end
end
