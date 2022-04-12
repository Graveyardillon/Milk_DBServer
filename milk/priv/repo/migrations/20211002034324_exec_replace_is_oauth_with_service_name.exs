defmodule Milk.Repo.Migrations.ExecReplaceIsOauthWithServiceName do
  use Ecto.Migration

  def change do
    alter table(:auth) do
      add :service_name, :string
    end

    execute "
    CREATE OR REPLACE FUNCTION loop1()
    RETURNS BOOLEAN
    AS $$
    DECLARE
      elem RECORD;
    BEGIN
      FOR elem IN SELECT * FROM auth
      LOOP
        IF elem.is_oauth THEN
          UPDATE auth SET service_name = 'discord' WHERE id = elem.id;
        ELSE
          UPDATE auth SET service_name = 'e-players' WHERE id = elem.id;
        END IF;
      END LOOP;

      RETURN TRUE;
    END;
    $$
    LANGUAGE 'plpgsql';
    "

    execute "SELECT loop1();"

    alter table(:auth) do
      remove :is_oauth
    end
  end
end
