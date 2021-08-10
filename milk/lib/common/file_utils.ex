defmodule Common.FileUtils do
  def copy(file_path, cp_path) do
    cp_dir = Path.dirname(cp_path)

    File.dir?(cp_dir)
    |> unless do
      File.mkdir_p(cp_dir)
    end

    File.cp(file_path, cp_path)
  end
end
