class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false, limit: 120
      t.text :description
      t.date :due_on
      t.integer :priority, null: false, default: 1
      t.boolean :completed, null: false, default: false
      t.timestamps
    end
    add_index :tasks, [ :completed, :due_on ]
    add_check_constraint :tasks, "priority IN (0, 1, 2)", name: "tasks_priority_range"
    add_check_constraint :tasks, "length(trim(title)) BETWEEN 1 AND 120", name: "tasks_title_length"
  end
end
