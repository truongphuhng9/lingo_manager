defmodule LingoManager.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :task_id, :string
    field :start_datetime, :naive_datetime
    field :audio_length_minutes, :decimal
    field :task_value_dollars, :decimal
    field :rate_per_hour, :decimal
    field :status, :string, default: "pending"
    field :finished_at, :naive_datetime
    field :paid, :boolean, default: false

    belongs_to :assigned_user, LingoManager.Accounts.User
    belongs_to :resource, LingoManager.Resources.Resource

    has_many :time_logs, LingoManager.TimeLogs.TimeLog

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [
      :task_id,
      :start_datetime,
      :audio_length_minutes,
      :task_value_dollars,
      :rate_per_hour,
      :status,
      :finished_at,
      :assigned_user_id,
      :resource_id,
      :paid
    ])
    |> validate_required([:task_id, :task_value_dollars, :rate_per_hour, :resource_id])
    |> validate_inclusion(:status, ["pending", "in_progress", "completed", "cancelled"])
    |> validate_number(:task_value_dollars, greater_than: 0)
    |> validate_number(:rate_per_hour, greater_than: 0)
    |> validate_number(:audio_length_minutes, greater_than_or_equal_to: 0)
    |> unique_constraint(:task_id)
  end

  def start_changeset(task) do
    task
    |> change(status: "in_progress", start_datetime: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
  end

  def complete_changeset(task) do
    task
    |> change(status: "completed", finished_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
  end

  def cancel_changeset(task) do
    task
    |> change(status: "cancelled")
  end

  def pending?(task), do: task.status == "pending"
  def in_progress?(task), do: task.status == "in_progress"
  def completed?(task), do: task.status == "completed"
  def cancelled?(task), do: task.status == "cancelled"

  def calculate_total_minutes(task) do
    if task.time_logs && length(task.time_logs) > 0 do
      Enum.reduce(task.time_logs, Decimal.new(0), fn log, acc ->
        if log.duration_minutes do
          Decimal.add(acc, log.duration_minutes)
        else
          acc
        end
      end)
    else
      Decimal.new(0)
    end
  end

  def calculate_earnings(task) do
    total_minutes = calculate_total_minutes(task)
    hours = Decimal.div(total_minutes, Decimal.new(60))
    Decimal.mult(hours, task.rate_per_hour)
  end
end