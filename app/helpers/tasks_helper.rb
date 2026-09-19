module TasksHelper
  PRIORITY_LABELS = { "low" => "低", "normal" => "中", "high" => "高" }.freeze

  def priority_options
    PRIORITY_LABELS.map { |value, label| [ label, value ] }
  end

  def task_due_label(task)
    return "期限なし" unless task.due_on
    return "今日まで" if task.due_on == Date.current
    return "明日まで" if task.due_on == Date.tomorrow
    l(task.due_on, format: :short)
  end

  def icon(name, **options)
    paths = {
      "check" => "M5 12l4 4L19 6",
      "plus" => "M12 5v14M5 12h14",
      "calendar" => "M8 3v4m8-4v4M4 10h16M5 5h14a1 1 0 0 1 1 1v14H4V6a1 1 0 0 1 1-1Z",
      "arrow" => "M19 12H5m6-6-6 6 6 6",
      "list" => "M9 6h11M9 12h11M9 18h11M4 6h.01M4 12h.01M4 18h.01"
    }
    tag.svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": 1.7,
      "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": true, **options) do
      tag.path(d: paths.fetch(name))
    end
  end
end
