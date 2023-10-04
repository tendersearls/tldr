class TLDR
  class Watcher
    def watch config
      require_fs_watch!
      command = "fswatch -o #{config.load_paths.reverse.join(" ")} | xargs -n1 -I{} #{tldr_command} #{config.to_full_args}"

      puts <<~MSG
        Watching #{config.load_paths.map(&:inspect).join(", ")} for changes...
      MSG

      exec command
    end

    private

    def require_fs_watch!
      `which fswatch`
      return if $?.success?

      warn <<~MSG
        Error: fswatch must be installed and on your PATH to run TLDR in --watch mode

        See: https://github.com/emcrisostomo/fswatch
      MSG
      exit 1
    end

    def tldr_command
      "#{"bundle exec " if defined?(Bundler)}tldr"
    end
  end
end
