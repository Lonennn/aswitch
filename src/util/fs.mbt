///|
/// Create the specified directory if the entry is not existed.
/// Success if the given directory exists or created successfully
pub fn create_dirs(dir : @path.Path) -> Unit raise @fs.IOError {
  if @fs.path_exists(dir.to_string()) {
    if @fs.is_file(dir.to_string()) {
      raise @fs.IOError("'\{dir}' is a file, failed to create this directory")
    }
    return
  }
  let parent = dir.dirname()
  if parent != dir {
    // create recursively
    create_dirs(parent)
  }
  @fs.create_dir(dir.to_string())
}
