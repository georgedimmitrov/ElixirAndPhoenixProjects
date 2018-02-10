defmodule Discuss.TopicController do
  use Discuss.Web, :controller

  # instead of using Discuss.Topic use Topic throughout file
  alias Discuss.Topic

  # use this plug only for functions in []
  plug Discuss.Plugs.RequireAuth when action in [:new, :create, :edit, :update, :delete]
  plug :check_topic_owner when action in [:update, :edit, :delete]

  # function name should match template file name (new.html.eex)

  # show all topics
  def index(conn, _params) do
    IO.inspect(conn.assigns)
    # get all topics in DB
    topics = Repo.all(Topic)

    render conn, "index.html", topics: topics
  end

  # create new topic
  def new(conn, _params) do
    changeset = Topic.changeset(%Topic{}, %{})

    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"topic" => topic}) do
    # conn.assigns.user and conn.assigns[:user] both return the current user
    changeset = conn.assigns.user
      # add relationship user has a topic associated with it
      |> build_assoc(:topics)
      |> Topic.changeset(topic)

    case Repo.insert(changeset) do
      {:ok, _topic} ->
        conn
        |> put_flash(:info, "Topic Created") # show flash msg
        |> redirect(to: topic_path(conn, :index)) # redirect to /
      {:error, changeset} ->
        render conn, "new.html", changeset: changeset
    end
  end

  # edit existing topic
  def edit(conn, %{"id" => topic_id}) do
    # fetch topic from DB
    topic = Repo.get(Topic, topic_id)
    # create a changeset out of the topic because the form helpers expect a changeset
    changeset = Topic.changeset(topic)

    render conn, "edit.html", changeset: changeset, topic: topic
  end

  def update(conn, %{"id" => topic_id, "topic" => topic}) do
    # fetch old topic from DB
    old_topic = Repo.get(Topic, topic_id)
    # generate updated changeset
    changeset = Topic.changeset(old_topic, topic)

    case Repo.update(changeset) do
      {:ok, _topic} ->
        conn
        |> put_flash(:info, "Topic Updated")
        |> redirect(to: topic_path(conn, :index))
      {:error, changeset} ->
        render conn, "edit.html", changeset: changeset, topic: old_topic
    end
  end

  def delete(conn, %{"id" => topic_id}) do
    Repo.get!(Topic, topic_id) |> Repo.delete!

    conn
    |> put_flash(:info, "Topic Deleted")
    |> redirect(to: topic_path(conn, :index))
  end

  # function plug since it is specific for this controller
  def check_topic_owner(conn, _params) do
    %{params: %{"id" => topic_id}} = conn

    # fetch topic that user is trying to access and if its id == user's id -> let conn pass
    if Repo.get(Topic, topic_id).user_id == conn.assigns.user.id do
      conn
    else
      conn
      |> put_flash(:error, "You cannot edit what you do not own.")
      |> redirect(to: topic_path(conn, :index))
      |> halt()
    end
  end
end