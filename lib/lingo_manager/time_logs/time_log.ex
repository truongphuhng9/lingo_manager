defmodule LingoManager.TimeLogs.TimeLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "time_logs" do
    field :start_time, :naive_datetime
    field :end_time, :naive_datetime
    field :duration_minutes, :decimal
    field :notes, :string

    belongs_to :user, LingoManager.Accounts.User
    belongs_to :task, LingoManager.Tasks.Task

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(time_log, attrs) do
    time_log
    |> cast(attrs, [:start_time, :end_time, :duration_minutes, :notes, :user_id, :task_id])
    |> validate_required([:start_time, :user_id, :task_id])
    |> validate_number(:duration_minutes, greater_than_or_equal_to: 0)
    |> validate_end_time_after_start_time()
    |> calculate_duration()
  end

  def start_changeset(time_log, attrs) do
    time_log
    |> cast(attrs, [:user_id, :task_id, :notes])
    |> validate_required([:user_id, :task_id])
    |> put_change(:start_time, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
  end

  def end_changeset(time_log, attrs \\ %{}) do
    end_time = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    time_log
    |> cast(attrs, [:notes])
    |> put_change(:end_time, end_time)
    |> calculate_duration()
  end

  defp validate_end_time_after_start_time(changeset) do
    start_time = get_field(changeset, :start_time)
    end_time = get_field(changeset, :end_time)

    if start_time && end_time && NaiveDateTime.compare(end_time, start_time) == :lt do
      add_error(changeset, :end_time, "must be after start time")
    else
      changeset
    end
  end

  defp calculate_duration(changeset) do
    start_time = get_field(changeset, :start_time)
    end_time = get_field(changeset, :end_time)

    if start_time && end_time do
      diff_seconds = NaiveDateTime.diff(end_time, start_time, :second)
      duration_minutes = Decimal.div(Decimal.new(diff_seconds), Decimal.new(60))
      put_change(changeset, :duration_minutes, duration_minutes)
    else
      changeset
    end
  end

  def active?(time_log) do
    time_log.start_time && !time_log.end_time
  end

  def completed?(time_log) do
    time_log.start_time && time_log.end_time
  end
end