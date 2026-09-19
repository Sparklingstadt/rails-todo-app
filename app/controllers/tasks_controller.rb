class TasksController < ApplicationController
  before_action :set_task, only: %i[edit update destroy completion]

  def index
    @task = Task.new
    load_tasks
  end

  def new
    @task = Task.new
  end

  def create
    @task = Task.new(task_params)
    if @task.save
      redirect_to root_path, notice: "タスクを追加しました。", status: :see_other
    else
      load_tasks
      render :index, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @task.update(task_params)
      redirect_to root_path, notice: "タスクを更新しました。", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def completion
    if @task.update(params.expect(task: [ :completed ]))
      message = @task.completed? ? "タスクを完了しました。おつかれさまです！" : "タスクを未完了に戻しました。"
      redirect_to root_path(status: filter_status), notice: message, status: :see_other
    else
      redirect_to root_path(status: filter_status), alert: "完了状態を変更できませんでした。", status: :see_other
    end
  end

  def destroy
    @task.destroy!
    redirect_to root_path, notice: "タスクを削除しました。", status: :see_other
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.expect(task: [ :title, :description, :due_on, :priority ])
  end

  def filter_status
    %w[all incomplete complete].include?(params[:status]) ? params[:status] : "all"
  end

  def load_tasks
    @status = filter_status
    @counts = Task.group(:completed).count
    @total_count = @counts.values.sum
    @completed_count = @counts.fetch(true, 0)
    @incomplete_count = @counts.fetch(false, 0)
    @completion_rate = @total_count.zero? ? 0 : (@completed_count * 100.0 / @total_count).round
    @tasks = case @status
    when "incomplete" then Task.incomplete
    when "complete" then Task.complete
    else Task.all
    end.ordered
  end
end
