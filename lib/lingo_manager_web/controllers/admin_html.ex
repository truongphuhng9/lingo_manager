defmodule LingoManagerWeb.AdminHTML do
  @moduledoc """
  This module contains pages rendered by AdminController.
  """
  use LingoManagerWeb, :html

  embed_templates "admin_html/*"
end