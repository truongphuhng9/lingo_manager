defmodule LingoManager.TimeLogs do
  @moduledoc """
  The TimeLogs context.
  """

  import Ecto.Query, warn: false
  alias LingoManager.Repo
  alias LingoManager.TimeLogs.TimeLog

  @doc """
  Returns the list of time logs for a user.
  """
  def list_user_time_logs(user_id) do
    TimeLog
    |> where([tl], tl.user_id == ^user_id)
    |> preload([:user, :task])
    |> order_by([tl], desc: tl.start_time)
    |> Repo.all()
  end

  @doc """
  Returns the list of time logs for a task.
  """
  def list_task_time_logs(task_id) do
    TimeLog
    |> where([tl], tl.task_id == ^task_id)
    |> preload([:user, :task])
    |> order_by([tl], asc: tl.start_time)
    |> Repo.all()
  end

  @doc """
  Gets a single time log.
  """
  def get_time_log!(id) do
    TimeLog
    |> preload([:user, :task])
    |> Repo.get!(id)
  end

  @doc """
  Gets the current active time log for a user.
  """
  def get_active_time_log_for_user(user_id) do
    TimeLog
    |> where([tl], tl.user_id == ^user_id and is_nil(tl.end_time))
    |> preload([:user, :task])
    |> Repo.one()
  end

  @doc """
  Starts a new time log for a task.
  """
  def start_time_log(attrs) do
    %TimeLog{}
    |> TimeLog.start_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Ends an active time log.
  """
  def end_time_log(%TimeLog{} = time_log, attrs \\ %{}) do
    if TimeLog.active?(time_log) do
      time_log
      |> TimeLog.end_changeset(attrs)
      |> Repo.update()
    else
      {:error, :time_log_not_active}
    end
  end

  @doc """
  Creates a time log with both start and end times.
  """
  def create_time_log(attrs) do
    %TimeLog{}
    |> TimeLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a time log.
  """
  def update_time_log(%TimeLog{} = time_log, attrs) do
    time_log
    |> TimeLog.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a time log.
  """
  def delete_time_log(%TimeLog{} = time_log) do
    Repo.delete(time_log)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking time log changes.
  """
  def change_time_log(%TimeLog{} = time_log, attrs \\ %{}) do
    TimeLog.changeset(time_log, attrs)
  end

  @doc """
  Calculates total time logged for a task.
  """
  def calculate_total_time_for_task(task_id) do
    TimeLog
    |> where([tl], tl.task_id == ^task_id and not is_nil(tl.duration_minutes))
    |> select([tl], sum(tl.duration_minutes))
    |> Repo.one() || Decimal.new(0)
  end

  @doc """
  Calculates total time logged by a user.
  """
  def calculate_total_time_for_user(user_id) do
    TimeLog
    |> where([tl], tl.user_id == ^user_id and not is_nil(tl.duration_minutes))
    |> select([tl], sum(tl.duration_minutes))
    |> Repo.one() || Decimal.new(0)
  end
end