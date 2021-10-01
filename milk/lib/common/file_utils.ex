defmodule Common.FileUtils do
  def copy(file_path, cp_path) do
    cp_dir = Path.dirname(cp_path)

    cp_dir
    |> File.dir?()
    |> unless do
      File.mkdir_p(cp_dir)
    end

    File.cp(file_path, cp_path)
  end

  def write(file_path, raw) do
    dir = Path.dirname(file_path)

    dir
    |> File.dir?()
    |> unless do
      File.mkdir_p(dir)
    end

    File.write(file_path, raw)
  end
end
