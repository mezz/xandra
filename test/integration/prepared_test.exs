defmodule PreparedTest do
  use XandraTest.IntegrationCase, async: true

  setup_all %{keyspace: keyspace} do
    {:ok, conn} = Xandra.start_link()
    Xandra.execute!(conn, "USE #{keyspace}", [])

    statement = "CREATE TABLE users (code int, name text, PRIMARY KEY (code, name))"
    Xandra.execute!(conn, statement, [])

    statement = """
    BEGIN BATCH
    INSERT INTO users (code, name) VALUES (1, 'Marge');
    INSERT INTO users (code, name) VALUES (1, 'Homer');
    INSERT INTO users (code, name) VALUES (1, 'Lisa');
    INSERT INTO users (code, name) VALUES (2, 'Moe');
    INSERT INTO users (code, name) VALUES (3, 'Ned');
    INSERT INTO users (code, name) VALUES (3, 'Burns');
    INSERT INTO users (code, name) VALUES (4, 'Bob');
    APPLY BATCH
    """
    Xandra.execute!(conn, statement, [])

    :ok
  end

  test "prepared functionality", %{conn: conn} do
    statement = "SELECT name FROM users WHERE code = :code"
    assert {:ok, prepared} = Xandra.prepare(conn, statement)
    # Successive call to prepare uses cache.
    assert {:ok, ^prepared} = Xandra.prepare(conn, statement)

    assert {:ok, page} = Xandra.execute(conn, prepared, [1])
    assert Enum.to_list(page) == [
      %{"name" => "Homer"}, %{"name" => "Lisa"}, %{"name" => "Marge"}
    ]

    assert {:ok, page} = Xandra.execute(conn, prepared, %{"code" => 2})
    assert Enum.to_list(page) == [
      %{"name" => "Moe"}
    ]

    assert {:ok, page} = Xandra.execute(conn, prepared, %{"code" => 5})
    assert Enum.to_list(page) == []
  end
end
